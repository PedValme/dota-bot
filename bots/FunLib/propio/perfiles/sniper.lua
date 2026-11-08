-- dota-bot's own bot: the Sniper's build profile (trabajo/build-estrategica.md, firmado por Pedro el 2026-11-08). A fixed core, then
-- points where the enemies decide: in each, the first candidate whose rule holds wins, the last one is the default. `uso` names the
-- rule that uses the item (build.lua's USES): an active item with none is never bought. Blade/Silver Edge and Force/Pike are Pedro's
-- choice (2026-11-05): the rules move them, never remove them.
return {
	-- Measured core, the same against everyone (DECISIONES 2026-11-04): stats, agility Treads, Dragon Lance soon.
	core = { 'item_wraith_band', 'item_power_treads', 'item_dragon_lance' },
	points = {
		-- After the Lance, with two or more heroes that jump on it, the Pike first. No Mask of Madness: in this build it cost 1.900 before
		-- the Maelstrom and put Maelstrom and Blade 3-4 min later (MEDICIONES, `build1`; Pedro, 2026-11-08: «quita la máscara»).
		{ name = 'A',
			{ item = 'item_hurricane_pike', uso = 'pike', when = function(t) return t.salta >= 2 end, why = 'rivales que saltan encima' } },
		{ name = 'Maelstrom', { item = 'item_maelstrom', uso = 'pasivo', why = 'núcleo' } },
		-- Before the Blade: the Black King Bar, against a team built on magic or lock. With two or more it held in nearly every lineup of
		-- the bench: a rule that always holds is a default, not a choice. Like this, 77 of 122 (planes sin partidas, 2026-11-08).
		{ name = 'B',
			{ item = 'item_black_king_bar', uso = 'bkb', when = function(t) return t.magia >= 3 or t.control >= 4 end, why = 'mucha magia o control' },
			{ item = 'item_invis_sword', uso = 'blade', why = 'entrar oculto (Pedro, 2026-11-05)' } },
		{ name = 'Blade', { item = 'item_invis_sword', uso = 'blade', why = 'entrar oculto (Pedro, 2026-11-05)' } },
		{ name = 'Pike', { item = 'item_hurricane_pike', uso = 'pike', why = 'separarse (Pedro, 2026-11-05)' } },
		{ name = 'BKB', { item = 'item_black_king_bar', uso = 'bkb', why = 'núcleo' } },
		{ name = 'Silver Edge', { item = 'item_silver_edge', uso = 'blade', why = 'entrar oculto (Pedro, 2026-11-05)' } },
		-- Mjollnir and Satanic are bought for what they do on their own; their actives have no rule yet.
		{ name = 'Mjollnir', { item = 'item_mjollnir', uso = 'pasivo', why = 'núcleo' } },
		{ name = 'C',
			{ item = 'item_monkey_king_bar', uso = 'pasivo', when = function(t) return t.evasion >= 1 end, why = 'evasión' },
			{ item = 'item_greater_crit', uso = 'pasivo', why = 'daño' } },
		{ name = 'Satanic', { item = 'item_satanic', uso = 'pasivo', why = 'núcleo' } },
	},
}
