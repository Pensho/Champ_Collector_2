class_name TeamCorpus extends RefCounted

## A pluggable input to Scripts/Debug/burst_reachability.gd, not a fixed list — the curated
## team sets Concept_Document.md 1.1 eventually wants do not exist yet, so this file holds
## whatever set is current. The scorer reads this file and nothing else knows it exists:
## replacing PROVISIONAL_ROWS later is editing this one data file, not touching the tool.
##
## Row shape is deliberately thin: three presets, a tier, and an optional one-sentence note
## on the realisation the team is meant to deliver. The bursting champion and skill are NOT
## row fields — BurstReachability.ScoreTeam derives them, so a row can never accidentally
## assert which resolution should win. "pinned" exists only for the two regression fixtures
## that do name a bursting skill (also pinned directly in test_burst_reachability.gd); it is
## empty on every other row.

enum Tier
{
	## Teams believed to detonate — assembling them is meant to be a discovery.
	Intent,
	## Teams that look similar to an Intent team to a player but should not work. If these
	## score close to Intent, the realisation is not discoverable.
	Plausible_But_Wrong,
	## Teams drawn without regard to synergy. Establishes the floor.
	Control,
}

const SORCERER = preload("res://Data/Character_Player_Variants/Sorcerer.tres")
const CENTAUR_ARCHIVIST = preload("res://Data/Character_Player_Variants/Centaur_Archivist.tres")
const TACTICIAN = preload("res://Data/Character_Player_Variants/Tactician.tres")
const TIDAL_CORSAIR = preload("res://Data/Character_Player_Variants/Tidal_Corsair.tres")
const CULTIST = preload("res://Data/Character_Player_Variants/Cultist.tres")
const WARLORD = preload("res://Data/Character_Player_Variants/Warlord.tres")
const BAR_BRAWLER = preload("res://Data/Character_Player_Variants/Bar_Brawler.tres")
const SYMBIOTE = preload("res://Data/Character_Player_Variants/Symbiote.tres")
const CHRONOPHAGE = preload("res://Data/Character_Player_Variants/Chronophage.tres")
const ALCHEMIST = preload("res://Data/Character_Player_Variants/Alchemist.tres")
const APPRAISER = preload("res://Data/Character_Player_Variants/Appraiser.tres")

## Every row here is PROVISIONAL (see the "provisional" field): a Tests/manual/
## team_corpus_sweep.gd run over the full roster, not a curated set. Struck once real
## Intent/Plausible-but-wrong/Control sets exist.
const PROVISIONAL_ROWS: Array[Dictionary] = [
	# --- Intent: the two hand-computed teams from the deleted Plan_Kit_Reworks.md, now
	# reproduced by the scorer itself and pinned as regression fixtures (also pinned
	# directly in test_burst_reachability.gd). ---
	{
		"presets": [SORCERER, CENTAUR_ARCHIVIST, TACTICIAN],
		"tier": Tier.Intent,
		"note": "Cataclysmic Surge's Warped bucket, Scholar's Opportunist grant anchored to " +
				"the same debuff, and Tactician's unconditional Daunting Strength.",
		"pinned": {"caster_index": 0, "skill_name": "Cataclysmic Surge"},
		"provisional": true,
	},
	{
		"presets": [TIDAL_CORSAIR, CULTIST, WARLORD],
		"tier": Tier.Intent,
		"note": "Wrangle the Sea's trait_resource ceiling at 3 filled Steel stacks.",
		"pinned": {"caster_index": 0, "skill_name": "Corsairs Reckoning"},
		"provisional": true,
	},
	# --- Intent: the roster's actual current ceiling, per the full-sweep report
	# (Tests/manual/team_corpus_sweep.gd) — Tidal Corsair's Wrangle the Sea (1.8) composed
	# with Tactician's unconditional Daunting Strength grant (1.0): (1+1.8)*(1+1.0) = 5.6x,
	# 14.3x contrast ratio. The sweep's top 10 are all this same pairing with a
	# non-contributing third slot — a provisional sweep observation, not a curated
	# conclusion; whether that reflects a real coverage gap is for whoever next reviews the
	# sweep's own report to decide.
	{
		"presets": [BAR_BRAWLER, TACTICIAN, TIDAL_CORSAIR],
		"tier": Tier.Intent,
		"note": "Current roster ceiling (product 5.6x): Wrangle the Sea x Daunting Strength.",
		"pinned": {},
		"provisional": true,
	},
	{
		"presets": [SYMBIOTE, TACTICIAN, TIDAL_CORSAIR],
		"tier": Tier.Intent,
		"note": "Same ceiling pairing as above with a different, equally inert third slot.",
		"pinned": {},
		"provisional": true,
	},
	# --- Control: teams drawn without regard to synergy — the sweep's actual floor
	# (product 1.0x, three Channel-1-only skills, no reachable bucket at all). ---
	{
		"presets": [CENTAUR_ARCHIVIST, CHRONOPHAGE, SYMBIOTE],
		"tier": Tier.Control,
		"note": "",
		"pinned": {},
		"provisional": true,
	},
	{
		"presets": [ALCHEMIST, CENTAUR_ARCHIVIST, CHRONOPHAGE],
		"tier": Tier.Control,
		"note": "No longer product 1.0x since Phase 5 of Plan_Itemization_Channels.md: any team " +
				"with an Alchemist now reaches Fresh Batch's team-wide reagent_gated_bonus " +
				"(assumed reachable per the manifest's reagent-assumed-available axis), a distinct " +
				"floor from the other two Control rows below rather than a synergy-free one.",
		"pinned": {},
		"provisional": true,
	},
	{
		"presets": [APPRAISER, CHRONOPHAGE, WARLORD],
		"tier": Tier.Control,
		"note": "",
		"pinned": {},
		"provisional": true,
	},
]
