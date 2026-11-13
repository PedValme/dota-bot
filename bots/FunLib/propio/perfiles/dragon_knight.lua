-- dota-bot's own bot: Dragon Knight's build profile, position 3 (trabajo/build-estrategica.md, firmado por Pedro el 2026-11-08). A
-- fixed core, then points where the enemies decide: in each, the first candidate whose rule holds wins, the last one is the default.
-- `uso` names the rule that uses the item (build.lua's USES): an active item with none is never bought, so OHA's pos_3 Orchid,
-- Crimson Guard, Heaven's Halberd, Blink and Bloodthorn wait for their rules; what is here works on its own.
return {
	-- A tanky start for the hard lane: the Bracer from the starting parts, strength Treads.
	core = { 'item_bracer', 'item_power_treads' },
	points = {
		-- Against a team built on magic or lock, the Black King Bar first: a frontline stunned or burst down does nothing. Else the
		-- Desolator, which makes its hits (melee, and ranged in Elder Dragon Form) take towers and heroes down.
		{ name = 'A',
			{ item = 'item_black_king_bar', uso = 'bkb', when = function(t) return t.magia >= 3 or t.control >= 4 end, why = 'mucha magia o control' },
			{ item = 'item_desolator', uso = 'pasivo', why = 'daño y armadura' } },
		{ name = 'Desolator', { item = 'item_desolator', uso = 'pasivo', why = 'núcleo' } },
		{ name = 'BKB', { item = 'item_black_king_bar', uso = 'bkb', why = 'núcleo' } },
		-- The aura helps the whole fight it stands in front of.
		{ name = 'Assault', { item = 'item_assault', uso = 'pasivo', why = 'aura para el equipo' } },
		{ name = 'C',
			{ item = 'item_monkey_king_bar', uso = 'pasivo', when = function(t) return t.evasion >= 1 end, why = 'evasión' },
			{ item = 'item_heart', uso = 'pasivo', why = 'aguantar en primera línea' } },
		-- Satanic is bought for what it does on its own; its active has no rule yet.
		{ name = 'Satanic', { item = 'item_satanic', uso = 'pasivo', why = 'núcleo' } },
	},
}
