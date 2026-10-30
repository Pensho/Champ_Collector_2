class_name TeamCorpus extends RefCounted

## The curated teams Tests/manual/team_corpus_sweep.gd reports on, one data file the scorer
## reads. Each row names three presets, a tier, and how the team is meant to play: its payoff,
## setup, protection and sequence. BurstReachability.ScoreTeam derives which skill wins, so a
## row cannot assert its own result. "pinned" names a bursting skill only for the two regression
## fixtures (also pinned directly in test_burst_reachability.gd) and for a row whose claim is
## about one specific skill.

enum Tier
{
	## Teams built to detonate.
	Intent,
	## Teams that look right to a player but should not work. If these score close to Intent,
	## the realisation is not discoverable.
	Plausible_But_Wrong,
	## Teams drawn without regard to synergy. Establishes the floor.
	Control,
}

const ALCHEMIST = preload("res://Data/Character_Player_Variants/Alchemist.tres")
const APPRAISER = preload("res://Data/Character_Player_Variants/Appraiser.tres")
const ARCHITECT = preload("res://Data/Character_Player_Variants/Architect.tres")
const BAR_BRAWLER = preload("res://Data/Character_Player_Variants/Bar_Brawler.tres")
const BLOODMAGE = preload("res://Data/Character_Player_Variants/Bloodmage.tres")
const CENTAUR_ARCHIVIST = preload("res://Data/Character_Player_Variants/Centaur_Archivist.tres")
const CENTAUR_LANCER = preload("res://Data/Character_Player_Variants/Centaur_Lancer.tres")
const CHRONOPHAGE = preload("res://Data/Character_Player_Variants/Chronophage.tres")
const CULTIST = preload("res://Data/Character_Player_Variants/Cultist.tres")
const DIVINER = preload("res://Data/Character_Player_Variants/Diviner.tres")
const EMISSARY = preload("res://Data/Character_Player_Variants/Emissary.tres")
const HERALD = preload("res://Data/Character_Player_Variants/Herald_of_the_loom.tres")
const JESTER = preload("res://Data/Character_Player_Variants/Jester.tres")
const PLAGUE_DOCTOR = preload("res://Data/Character_Player_Variants/Plague_Doctor.tres")
const SORCERER = preload("res://Data/Character_Player_Variants/Sorcerer.tres")
const SYMBIOTE = preload("res://Data/Character_Player_Variants/Symbiote.tres")
const TACTICIAN = preload("res://Data/Character_Player_Variants/Tactician.tres")
const THIEF = preload("res://Data/Character_Player_Variants/Thief.tres")
const TIDAL_CORSAIR = preload("res://Data/Character_Player_Variants/Tidal_Corsair.tres")
const WARLORD = preload("res://Data/Character_Player_Variants/Warlord.tres")

const ROWS: Array[Dictionary] = [
	{
		"presets": [SORCERER, CENTAUR_ARCHIVIST, TACTICIAN],
		"tier": Tier.Intent,
		"payoff": "Cataclysm",
		"setup": "Instability from each turn, Warped, Expose Fallacy's Opportunist.",
		"protection": "None; the Surge at the ceiling is the risk.",
		"sequence": "Build Instability, Expose Fallacy, Fatal Flaw, then Cataclysm below the Surge.",
		"pinned": {"caster_index": 0, "skill_name": "Cataclysm"},
	},
	{
		"presets": [SORCERER, BLOODMAGE, EMISSARY],
		"tier": Tier.Intent,
		"payoff": "Cataclysm",
		"setup": "Instability, Hemorrhage and Sanguine Pact on the Sorcerer, Infractions into Sanction.",
		"protection": "Transfusion's Barrier.",
		"sequence": "Build Instability and Infractions, Levied Sanction, Tithe of Vitality, Transfusion, Cataclysm.",
		"pinned": {},
	},
	{
		"presets": [HERALD, CENTAUR_ARCHIVIST, TACTICIAN],
		"tier": Tier.Intent,
		"payoff": "Cut the Cloth",
		"setup": "Tension from Pull the Thread and allies' casts, Opportunist.",
		"protection": "None.",
		"sequence": "Raise Tension, Expose Fallacy, Fatal Flaw, then Cut the Cloth.",
		"pinned": {},
	},
	{
		"presets": [HERALD, BLOODMAGE, DIVINER],
		"tier": Tier.Intent,
		"payoff": "Cut the Cloth",
		"setup": "Tension, Hemorrhage, Sanguine Pact on the Herald.",
		"protection": "Premonition on the carrier, Transfusion's Barrier.",
		"sequence": "Raise Tension, Tithe of Vitality, Transfusion, Premonition, then Cut the Cloth.",
		"pinned": {},
	},
	{
		"presets": [TIDAL_CORSAIR, CULTIST, WARLORD],
		"tier": Tier.Intent,
		"payoff": "Corsairs Reckoning",
		"setup": "Three Steel stacks, Fortify and Haste on an ally for Devour Blessing.",
		"protection": "Hold the Line's Aegis, Brace for Impact.",
		"sequence": "Boarding Strike three times, Hold the Line, then Corsairs Reckoning.",
		"pinned": {"caster_index": 0, "skill_name": "Corsairs Reckoning"},
	},
	{
		"presets": [TIDAL_CORSAIR, TACTICIAN, WARLORD],
		"tier": Tier.Intent,
		"payoff": "Corsairs Reckoning",
		"setup": "Three Steel stacks, Daunting Strength.",
		"protection": "Hold the Line's Aegis, Brace for Impact.",
		"sequence": "Boarding Strike three times, Fatal Flaw, then Corsairs Reckoning.",
		"pinned": {},
	},
	{
		"presets": [CULTIST, TACTICIAN, WARLORD],
		"tier": Tier.Intent,
		"payoff": "Devour Blessing",
		"setup": "Buffs on the most-buffed ally, Daunting Strength on the Cultist, the Vessel at the kill line.",
		"protection": "Hold the Line's Aegis, Brace for Impact on a non-Vessel window.",
		"sequence": "Hold the Line, Battle Orders, Rite of Severance on the Vessel, Fatal Flaw, a killing Devour Blessing.",
		"pinned": {},
	},
	{
		"presets": [PLAGUE_DOCTOR, CENTAUR_ARCHIVIST, JESTER],
		"tier": Tier.Intent,
		"payoff": "Plague ticks with Comorbidity",
		"setup": "Distinct debuff types: Plague, Blight, Confound, Suppress, Hexed, Burning.",
		"protection": "Spotlight on the Jester.",
		"sequence": "Stack debuff types, Outbreak, Miasma, then keep Plague up as the ticks grow.",
		"pinned": {},
	},
	{
		"presets": [ARCHITECT, TACTICIAN, DIVINER],
		"tier": Tier.Intent,
		"payoff": "Final Calculation",
		"setup": "Calibration charges from turns and Raise the Frame.",
		"protection": "Raise the Frame's Barrier, Premonition.",
		"sequence": "Build to the top charge tier, Fatal Flaw, then Final Calculation.",
		"pinned": {},
	},
	{
		"presets": [CENTAUR_LANCER, TACTICIAN, CENTAUR_ARCHIVIST],
		"tier": Tier.Intent,
		"payoff": "Rending Charge",
		"setup": "The target just acted, Opportunist across Bleed, Enfeeble and Confound, Daunting Strength.",
		"protection": "Disarm's Enfeeble.",
		"sequence": "Expose Fallacy, Disarm, Fatal Flaw, then Rending Charge after the target's turn.",
		"pinned": {},
	},
	{
		"presets": [CENTAUR_LANCER, TACTICIAN, CHRONOPHAGE],
		"tier": Tier.Intent,
		"payoff": "Rending Charge",
		"setup": "Temporal Sinkhole on the target, Borrowed Time from Flicker Zone, Daunting Strength.",
		"protection": "Disarm's Enfeeble, Temporal Sinkhole's lost enemy turns.",
		"sequence": "Temporal Sinkhole, Flicker Zone, Fatal Flaw, then Rending Charge with the Echo.",
		"pinned": {},
	},
	{
		"presets": [BAR_BRAWLER, TACTICIAN, APPRAISER],
		"tier": Tier.Intent,
		"payoff": "Heap On through Bar Fight",
		"setup": "Heap On uses every round, Full Appraisal's crit, Daunting Strength.",
		"protection": "On the House, Liquid Courage's cleanse.",
		"sequence": "Heap On from round 1, Flaw Analysis, Full Appraisal, Fatal Flaw, then Bar Fight.",
		"pinned": {},
	},
	{
		"presets": [BAR_BRAWLER, TACTICIAN, DIVINER],
		"tier": Tier.Intent,
		"payoff": "Heap On through Bar Fight",
		"setup": "Heap On uses every round, extra uses from Premonition's counter, Daunting Strength.",
		"protection": "Premonition, On the House, Liquid Courage's cleanse.",
		"sequence": "Heap On from round 1, Premonition on the Brawler, Fatal Flaw, then Bar Fight.",
		"pinned": {},
	},
	{
		"presets": [THIEF, EMISSARY, JESTER],
		"tier": Tier.Intent,
		"payoff": "Steady Opportunist damage",
		"setup": "Debuff types, Sanction, Cut Purse's Opportunist window.",
		"protection": "Hexed, Cut Purse's steal.",
		"sequence": "Stack debuff types and Sanction, Cut Purse, then attack through the window.",
		"pinned": {},
	},
	{
		"presets": [BAR_BRAWLER, WARLORD, SYMBIOTE],
		"tier": Tier.Plausible_But_Wrong,
		"payoff": "Heap On behind a wall of tanks",
		"setup": "Fortify and Regeneration keep Heap On going.",
		"protection": "All of the team; none of it multiplies Heap On.",
		"sequence": "Heap On every turn; the fight outlasts the round budget.",
		"pinned": {},
	},
	{
		"presets": [TIDAL_CORSAIR, CENTAUR_LANCER, WARLORD],
		"tier": Tier.Plausible_But_Wrong,
		"payoff": "Rending Charge at long distance",
		"setup": "Sea stacks look like push-back, but they only supply the Deck.",
		"protection": "Hold the Line, Brace for Impact.",
		"sequence": "Saltwater Shot, then Rending Charge; the distance does not grow.",
		"pinned": {"caster_index": 1, "skill_name": "Rending Charge"},
	},
	{
		"presets": [CULTIST, BAR_BRAWLER, WARLORD],
		"tier": Tier.Plausible_But_Wrong,
		"payoff": "Devour Blessing fed by heals and buffs",
		"setup": "Few buffs land on one ally, and no one supplies a factor.",
		"protection": "Hold the Line, On the House.",
		"sequence": "Liquid Courage and Hold the Line into Devour Blessing; the count stays low.",
		"pinned": {},
	},
	{
		"presets": [CENTAUR_ARCHIVIST, CHRONOPHAGE, SYMBIOTE],
		"tier": Tier.Control,
		"payoff": "",
		"setup": "",
		"protection": "",
		"sequence": "",
		"pinned": {},
	},
	{
		"presets": [ALCHEMIST, CENTAUR_ARCHIVIST, CHRONOPHAGE],
		"tier": Tier.Control,
		"payoff": "",
		"setup": "",
		"protection": "",
		"sequence": "",
		"pinned": {},
	},
	{
		"presets": [APPRAISER, CHRONOPHAGE, WARLORD],
		"tier": Tier.Control,
		"payoff": "",
		"setup": "",
		"protection": "",
		"sequence": "",
		"pinned": {},
	},
]
