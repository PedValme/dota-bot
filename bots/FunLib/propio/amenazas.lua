-- dota-bot's own bot: what each enemy hero threatens, for the build that answers it (trabajo/build-estrategica.md, firmado por
-- Pedro el 2026-11-08). Shared by every hero of ours. Judgement, not data: one line per hero with its reason; a hero missing here
-- just adds nothing. First version by hand for the heroes of the bench and those met in Pedro's lobbies; the design leaves for later a
-- tool that writes it from Valve's data files.
--   evasion   attacks miss: answered by Monkey King Bar
--   control   stuns, hexes or silences that lock us: two or more, Black King Bar sooner
--   magia     burst of magical damage: two or more, Black King Bar sooner
--   salta     closes the distance at once (blink, leap, charge): two or more, Hurricane Pike sooner
--   invis     goes invisible; ilusiones: makes illusions; curacion: heals much (no answer yet in the first version)
local A = {}

A.HEROES = {
	alchemist = { control = true },                       -- Unstable Concoction
	axe = { control = true, salta = true },               -- Berserker's Call after a Blink
	bane = { control = true },                            -- Nightmare, Fiend's Grip
	bloodseeker = { magia = true },                       -- Rupture
	bounty_hunter = { invis = true },                     -- Shadow Walk
	brewmaster = { evasion = true, control = true },      -- Drunken Brawler, Thunder Clap
	bristleback = {},
	centaur = { control = true },                         -- Hoof Stomp
	chaos_knight = { control = true, salta = true, ilusiones = true }, -- Chaos Bolt, Reality Rift, Phantasm
	clinkz = { invis = true },                            -- Skeleton Walk
	crystal_maiden = { control = true, magia = true },    -- Frostbite, Crystal Nova
	dazzle = { curacion = true },                         -- Shallow Grave, Shadow Wave
	death_prophet = { magia = true },                     -- Exorcism, Crypt Swarm
	dragon_knight = { control = true },                   -- Dragon Tail
	drow_ranger = {},
	earthshaker = { control = true, salta = true, magia = true }, -- Fissure, Echo Slam after a Blink
	faceless_void = { control = true, salta = true },     -- Chronosphere, Time Walk
	jakiro = { control = true, magia = true },            -- Ice Path, Macropyre
	juggernaut = { curacion = true },                     -- Healing Ward
	kez = { salta = true },                               -- closes at once with its dashes
	kunkka = { control = true },                          -- Torrent, X Marks the Spot
	lich = { magia = true },                              -- Chain Frost
	lina = { control = true, magia = true },              -- Light Strike Array, Laguna Blade
	lion = { control = true, magia = true },              -- Hex, Impale, Finger of Death
	luna = { magia = true },                              -- Eclipse
	medusa = {},
	mirana = { control = true },                          -- Sacred Arrow
	monkey_king = { salta = true },                       -- Tree Dance
	naga_siren = { ilusiones = true },                    -- Mirror Image
	necrolyte = { magia = true, curacion = true },        -- Reaper's Scythe, Death Pulse
	nevermore = { magia = true },                         -- Shadowraze, Requiem
	nyx_assassin = { invis = true, control = true },      -- Vendetta, Impale
	ogre_magi = { control = true, magia = true },         -- Fireblast
	omniknight = { curacion = true },                     -- Purification
	oracle = { curacion = true },                         -- False Promise
	phantom_assassin = { evasion = true, salta = true },  -- Blur, Phantom Strike
	phantom_lancer = { ilusiones = true },                -- Juxtapose
	pudge = { control = true, salta = true },             -- Meat Hook pulls it in, Dismember
	razor = {},
	riki = { invis = true, salta = true },                -- Cloak and Dagger, Blink Strike
	sand_king = { control = true, salta = true },         -- Burrowstrike
	shadow_shaman = { control = true },                   -- Hex, Shackles
	skeleton_king = { control = true },                   -- Wraithfire Blast
	skywrath_mage = { magia = true },                     -- Mystic Flare
	slark = { salta = true, curacion = true },            -- Pounce, Shadow Dance
	sniper = {},
	sven = { control = true },                            -- Storm Hammer
	terrorblade = { ilusiones = true },                   -- Conjure Image
	tidehunter = { control = true },                      -- Ravage
	tiny = { control = true, magia = true },              -- Avalanche and Toss
	ursa = { salta = true },                              -- Earthshock leaps in
	vengefulspirit = { control = true },                  -- Magic Missile
	viper = { magia = true },                             -- Poison Attack, Viper Strike
	warlock = { control = true, magia = true },           -- Chaotic Offering
	weaver = { invis = true, evasion = true },            -- Shukuchi, Time Lapse
	windrunner = { evasion = true, control = true },      -- Windrun, Shackleshot
	witch_doctor = { control = true, magia = true, curacion = true }, -- Paralyzing Cask, Death Ward, Voodoo Restoration
	zuus = { magia = true },                              -- Lightning Bolt, Thundergod's Wrath
}

-- An item seen on an enemy adds its threat to that hero.
A.ITEMS = {
	item_butterfly = 'evasion',
	item_blink = 'salta', item_overwhelming_blink = 'salta', item_swift_blink = 'salta', item_arcane_blink = 'salta',
	item_shadow_blade = 'invis', item_invis_sword = 'invis', item_silver_edge = 'invis',
	item_manta = 'ilusiones',
}

return A
