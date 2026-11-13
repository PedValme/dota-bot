-- dota-bot's own bot: Luna's build profile, in the Sniper's format (trabajo/build-estrategica.md). A fixed core, then points where
-- the enemies decide: in each, the first candidate whose rule holds wins, the last one is the default. `uso` names the rule that
-- uses the item (build.lua's USES): an active item with none is never bought. Taken from OHA's pos_1 list and Valve's loadout,
-- keeping only items with a rule; not measured yet.
return {
	-- Stats, agility Treads, and Mask of Madness for the farm and the fights (its active has a rule: berserk).
	core = { 'item_wraith_band', 'item_power_treads', 'item_mask_of_madness' },
	points = {
		-- Luna attacks from 330: the Lance's range is what lets her hit without standing in the enemy's reach.
		{ name = 'Lance', { item = 'item_dragon_lance', uso = 'pasivo', why = 'alcance de ataque corto' } },
		-- Before Manta: the Black King Bar, against a team built on magic or lock, as in the Sniper's profile.
		{ name = 'A',
			{ item = 'item_black_king_bar', uso = 'bkb', when = function(t) return t.magia >= 3 or t.control >= 4 end, why = 'mucha magia o control' },
			{ item = 'item_manta', uso = 'pasivo', why = 'núcleo' } },
		-- Manta is bought for its stats; its active has no rule yet.
		{ name = 'Manta', { item = 'item_manta', uso = 'pasivo', why = 'núcleo' } },
		{ name = 'BKB', { item = 'item_black_king_bar', uso = 'bkb', why = 'núcleo' } },
		-- With two or more heroes that jump on her, the Pike to separate (it is built from the Lance above); else the Satanic.
		{ name = 'B',
			{ item = 'item_hurricane_pike', uso = 'pike', when = function(t) return t.salta >= 2 end, why = 'rivales que saltan encima' },
			{ item = 'item_satanic', uso = 'pasivo', why = 'núcleo' } },
		-- Satanic's active has no rule yet; it is bought for its lifesteal.
		{ name = 'Satanic', { item = 'item_satanic', uso = 'pasivo', why = 'núcleo' } },
		{ name = 'C',
			{ item = 'item_monkey_king_bar', uso = 'pasivo', when = function(t) return t.evasion >= 1 end, why = 'evasión' },
			{ item = 'item_butterfly', uso = 'pasivo', why = 'daño y evasión' } },
	},
}
