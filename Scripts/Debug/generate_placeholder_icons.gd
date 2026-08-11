@tool
extends EditorScript

## Data-driven generator for flat-color placeholder icon textures, following
## Scripts/Debug/generate_placeholder_textures.gd's recipe.
##
## Reagent rows are rarity-tiered: each writes one PNG per tier, the base hue blended
## toward that tier's tint, to <ICON_ROOT>/<folder>/<base_name>_<rarity>.png. Status-effect
## and skill rows are flat: each writes a single <ICON_ROOT>/<folder>/<base_name>.png.
##
## Existing files are skipped so hand-replaced real art is never clobbered; set
## OVERWRITE to true to force regeneration.
##
## Run headless:
##   godot --headless -s res://Scripts/Debug/generate_placeholder_icons.gd

const OVERWRITE: bool = false
const ICON_ROOT: String = "res://Assets/Champ_Collector/Icons"
const CREATURE_ROOT: String = "res://Assets/Champ_Collector/Creatures/Opponents"

# One row per reagent family. Each family gets one icon per rarity tier, all sharing
# this base hue blended toward the rarity's tint (see RARITY_TINTS).
#   folder, base_name, size, base_color
const REAGENT_FAMILY_TABLE: Array = [
	{ "folder": "Reagents/Tincture_Speed", "base_name": "Tincture_Speed", "size": 64,
			"color": Color(0.85, 0.75, 0.15, 1.0) },
	{ "folder": "Reagents/Tincture_Attack", "base_name": "Tincture_Attack", "size": 64,
			"color": Color(0.80, 0.30, 0.15, 1.0) },
	{ "folder": "Reagents/Tincture_Defence", "base_name": "Tincture_Defence", "size": 64,
			"color": Color(0.35, 0.45, 0.65, 1.0) },
	{ "folder": "Reagents/Tincture_Accuracy", "base_name": "Tincture_Accuracy", "size": 64,
			"color": Color(0.20, 0.65, 0.60, 1.0) },
	{ "folder": "Reagents/Tincture_Resistance", "base_name": "Tincture_Resistance", "size": 64,
			"color": Color(0.55, 0.40, 0.25, 1.0) },
	{ "folder": "Reagents/Tincture_Mysticism", "base_name": "Tincture_Mysticism", "size": 64,
			"color": Color(0.55, 0.30, 0.75, 1.0) },
	{ "folder": "Reagents/Tincture_Knowledge", "base_name": "Tincture_Knowledge", "size": 64,
			"color": Color(0.25, 0.55, 0.75, 1.0) },
	{ "folder": "Reagents/Tincture_CritChance", "base_name": "Tincture_CritChance", "size": 64,
			"color": Color(0.85, 0.35, 0.55, 1.0) },
	{ "folder": "Reagents/Tincture_CritDamage", "base_name": "Tincture_CritDamage", "size": 64,
			"color": Color(0.70, 0.15, 0.20, 1.0) },
	{ "folder": "Reagents/Restorative_Draught", "base_name": "Restorative_Draught", "size": 64,
			"color": Color(0.35, 0.75, 0.40, 1.0) },
	{ "folder": "Reagents/Purging_Tonic", "base_name": "Purging_Tonic", "size": 64,
			"color": Color(0.30, 0.80, 0.65, 1.0) },
	{ "folder": "Reagents/Thiefs_Regret", "base_name": "Thiefs_Regret", "size": 64,
			"color": Color(0.40, 0.20, 0.50, 1.0) },
	{ "folder": "Reagents/Rewinding_Grit", "base_name": "Rewinding_Grit", "size": 64,
			"color": Color(0.80, 0.65, 0.20, 1.0) },
	{ "folder": "Reagents/Second_Wind_Phial", "base_name": "Second_Wind_Phial", "size": 64,
			"color": Color(0.40, 0.70, 0.90, 1.0) },
	{ "folder": "Reagents/Zone_Dissolving_Salts", "base_name": "Zone_Dissolving_Salts", "size": 64,
			"color": Color(0.60, 0.60, 0.60, 1.0) },
	{ "folder": "Reagents/Chaotic_Blessing", "base_name": "Chaotic_Blessing", "size": 64,
			"color": Color(0.45, 0.50, 0.30, 1.0) },
	{ "folder": "Reagents/Fractured_Idol", "base_name": "Fractured_Idol", "size": 64,
			"color": Color(0.35, 0.12, 0.12, 1.0) },
]

# One row per batch-1 status effect (Plan_Status_Effect_Implementation.md). Status
# effects aren't rarity-tiered, so each row writes a single flat-color PNG rather than
# one per RARITY_TINTS entry. Buffs use a green/blue hue family, debuffs a red/purple
# one; each effect gets a distinct hue within its family.
#   folder, base_name, size, color
const STATUS_EFFECT_TABLE: Array = [
	# Debuffs (red/purple family)
	{ "folder": "Status_Effects/Suppress", "base_name": "Suppress", "size": 64,
			"color": Color(0.55, 0.20, 0.65, 1.0) },
	{ "folder": "Status_Effects/Slow", "base_name": "Slow", "size": 64,
			"color": Color(0.70, 0.30, 0.15, 1.0) },
	{ "folder": "Status_Effects/Blind", "base_name": "Blind", "size": 64,
			"color": Color(0.60, 0.15, 0.15, 1.0) },
	{ "folder": "Status_Effects/Unravel", "base_name": "Unravel", "size": 64,
			"color": Color(0.65, 0.25, 0.45, 1.0) },
	{ "folder": "Status_Effects/Confound", "base_name": "Confound", "size": 64,
			"color": Color(0.45, 0.15, 0.55, 1.0) },
	{ "folder": "Status_Effects/Exposed_Facet", "base_name": "Exposed_Facet", "size": 64,
			"color": Color(0.80, 0.35, 0.20, 1.0) },
	{ "folder": "Status_Effects/Cracked_Facet", "base_name": "Cracked_Facet", "size": 64,
			"color": Color(0.75, 0.10, 0.30, 1.0) },
	{ "folder": "Status_Effects/Sequence_Lock", "base_name": "Sequence_Lock", "size": 64,
			"color": Color(0.50, 0.10, 0.10, 1.0) },
	{ "folder": "Status_Effects/Bleed", "base_name": "Bleed", "size": 64,
			"color": Color(0.65, 0.05, 0.05, 1.0) },
	{ "folder": "Status_Effects/Plague", "base_name": "Plague", "size": 64,
			"color": Color(0.40, 0.30, 0.10, 1.0) },
	{ "folder": "Status_Effects/Blight", "base_name": "Blight", "size": 64,
			"color": Color(0.45, 0.15, 0.30, 1.0) },
	{ "folder": "Status_Effects/Temporal_Leak", "base_name": "Temporal_Leak", "size": 64,
			"color": Color(0.35, 0.15, 0.45, 1.0) },
	# Buffs (green/blue family)
	{ "folder": "Status_Effects/Attune", "base_name": "Attune", "size": 64,
			"color": Color(0.30, 0.55, 0.80, 1.0) },
	{ "folder": "Status_Effects/Haste", "base_name": "Haste", "size": 64,
			"color": Color(0.20, 0.75, 0.55, 1.0) },
	{ "folder": "Status_Effects/True_Aim", "base_name": "True_Aim", "size": 64,
			"color": Color(0.15, 0.65, 0.35, 1.0) },
	{ "folder": "Status_Effects/Clarity", "base_name": "Clarity", "size": 64,
			"color": Color(0.35, 0.80, 0.75, 1.0) },
	{ "folder": "Status_Effects/Insight", "base_name": "Insight", "size": 64,
			"color": Color(0.20, 0.45, 0.75, 1.0) },
	{ "folder": "Status_Effects/Vigor", "base_name": "Vigor", "size": 64,
			"color": Color(0.25, 0.70, 0.30, 1.0) },
	{ "folder": "Status_Effects/Keen_Edge", "base_name": "Keen_Edge", "size": 64,
			"color": Color(0.40, 0.70, 0.90, 1.0) },
	{ "folder": "Status_Effects/Lethal_Precision", "base_name": "Lethal_Precision", "size": 64,
			"color": Color(0.15, 0.55, 0.85, 1.0) },
	{ "folder": "Status_Effects/Frenzy", "base_name": "Frenzy", "size": 64,
			"color": Color(0.60, 0.75, 0.20, 1.0) },
	{ "folder": "Status_Effects/Opportunist", "base_name": "Opportunist", "size": 64,
			"color": Color(0.20, 0.60, 0.65, 1.0) },
	{ "folder": "Status_Effects/Regeneration", "base_name": "Regeneration", "size": 64,
			"color": Color(0.25, 0.80, 0.45, 1.0) },
	{ "folder": "Status_Effects/Exhert", "base_name": "Exhert", "size": 64,
			"color": Color(0.15, 0.60, 0.55, 1.0) },
	{ "folder": "Status_Effects/Mana_Burn", "base_name": "Mana_Burn", "size": 64,
			"color": Color(0.55, 0.05, 0.55, 1.0) },
	{ "folder": "Status_Effects/Hexed", "base_name": "Hexed", "size": 64,
			"color": Color(0.30, 0.05, 0.40, 1.0) },
	{ "folder": "Status_Effects/Premonition", "base_name": "Premonition", "size": 64,
			"color": Color(0.30, 0.65, 0.85, 1.0) },
	{ "folder": "Status_Effects/Deathward", "base_name": "Deathward", "size": 64,
			"color": Color(0.20, 0.80, 0.60, 1.0) },
	{ "folder": "Status_Effects/Aegis", "base_name": "Aegis", "size": 64,
			"color": Color(0.25, 0.55, 0.85, 1.0) },
	{ "folder": "Status_Effects/Mirror_Coat", "base_name": "Mirror_Coat", "size": 64,
			"color": Color(0.35, 0.75, 0.70, 1.0) },
	{ "folder": "Status_Effects/Barrier", "base_name": "Barrier", "size": 64,
			"color": Color(0.20, 0.50, 0.75, 1.0) },
	{ "folder": "Status_Effects/Luck", "base_name": "Luck", "size": 64,
			"color": Color(0.30, 0.80, 0.35, 1.0) },
	{ "folder": "Status_Effects/Rehearsed", "base_name": "Rehearsed", "size": 64,
			"color": Color(0.20, 0.70, 0.80, 1.0) },
	{ "folder": "Status_Effects/Overflow", "base_name": "Overflow", "size": 64,
			"color": Color(0.40, 0.60, 0.90, 1.0) },
	{ "folder": "Status_Effects/Wanderlust", "base_name": "Wanderlust", "size": 64,
			"color": Color(0.45, 0.80, 0.40, 1.0) },
	# Debuffs (red/purple family)
	{ "folder": "Status_Effects/Dead_Weight", "base_name": "Dead_Weight", "size": 64,
			"color": Color(0.45, 0.25, 0.10, 1.0) },
	{ "folder": "Status_Effects/Stun", "base_name": "Stun", "size": 64,
			"color": Color(0.75, 0.65, 0.10, 1.0) },
	{ "folder": "Status_Effects/Fatigue", "base_name": "Fatigue", "size": 64,
			"color": Color(0.50, 0.30, 0.20, 1.0) },
	{ "folder": "Status_Effects/Refracted", "base_name": "Refracted", "size": 64,
			"color": Color(0.55, 0.15, 0.50, 1.0) },
	{ "folder": "Status_Effects/Warped", "base_name": "Warped", "size": 64,
			"color": Color(0.40, 0.10, 0.60, 1.0) },
	{ "folder": "Status_Effects/Signed_Writ", "base_name": "Signed_Writ", "size": 64,
			"color": Color(0.60, 0.20, 0.20, 1.0) },
	{ "folder": "Status_Effects/Severance", "base_name": "Severance", "size": 64,
			"color": Color(0.35, 0.05, 0.35, 1.0) },
	{ "folder": "Status_Effects/Sanction", "base_name": "Sanction", "size": 64,
			"color": Color(0.55, 0.35, 0.10, 1.0) },
	{ "folder": "Status_Effects/Anchor", "base_name": "Anchor", "size": 64,
			"color": Color(0.25, 0.20, 0.35, 1.0) },
	# Buffs (green/blue family)
	{ "folder": "Status_Effects/Steadfast", "base_name": "Steadfast", "size": 64,
			"color": Color(0.20, 0.55, 0.45, 1.0) },
	{ "folder": "Status_Effects/Slipstream", "base_name": "Slipstream", "size": 64,
			"color": Color(0.30, 0.70, 0.85, 1.0) },
	{ "folder": "Status_Effects/Resonance", "base_name": "Resonance", "size": 64,
			"color": Color(0.35, 0.60, 0.90, 1.0) },
	{ "folder": "Status_Effects/Battle_Orders", "base_name": "Battle_Orders", "size": 64,
			"color": Color(0.20, 0.65, 0.40, 1.0) },
	{ "folder": "Status_Effects/Rush", "base_name": "Rush", "size": 64,
			"color": Color(0.55, 0.75, 0.25, 1.0) },
	{ "folder": "Status_Effects/Spotlight", "base_name": "Spotlight", "size": 64,
			"color": Color(0.85, 0.75, 0.30, 1.0) },
	{ "folder": "Status_Effects/Catalyst", "base_name": "Catalyst", "size": 64,
			"color": Color(0.25, 0.75, 0.65, 1.0) },
	{ "folder": "Status_Effects/Volatile_Mixture", "base_name": "Volatile_Mixture", "size": 64,
			"color": Color(0.65, 0.55, 0.15, 1.0) },
]

# One row per skill and passive still awaiting real art. Skills aren't rarity-tiered, so
# like the status table each row writes a single flat-color PNG. Champion skills live under
# Abilities/Role_Active_Skills, opponent skills under Abilities/Opponent_Active_Skills, and
# passives under Abilities/Passives. Each is grouped by owner with a distinct base hue.
#   folder, base_name, size, color
const SKILL_ICON_TABLE: Array = [
	# Champion skills (Role_Active_Skills)
	# Herald of the Loom
	{ "folder": "Abilities/Role_Active_Skills/Thread_Snap", "base_name": "Thread_Snap", "size": 64,
			"color": Color(0.20, 0.55, 0.60, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Pull_the_Thread", "base_name": "Pull_the_Thread", "size": 64,
			"color": Color(0.15, 0.45, 0.55, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Cut_the_Cloth", "base_name": "Cut_the_Cloth", "size": 64,
			"color": Color(0.30, 0.65, 0.60, 1.0) },
	# Thief
	{ "folder": "Abilities/Role_Active_Skills/Weigh_the_Mark", "base_name": "Weigh_the_Mark", "size": 64,
			"color": Color(0.45, 0.25, 0.55, 1.0) },
	# Alchemist
	{ "folder": "Abilities/Role_Active_Skills/Acrid_Splash", "base_name": "Acrid_Splash", "size": 64,
			"color": Color(0.55, 0.65, 0.20, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Dissolving_Agent", "base_name": "Dissolving_Agent", "size": 64,
			"color": Color(0.45, 0.60, 0.15, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Catalyst_Cloud", "base_name": "Catalyst_Cloud", "size": 64,
			"color": Color(0.35, 0.70, 0.40, 1.0) },
	# Sorcerer
	{ "folder": "Abilities/Role_Active_Skills/Arc_Lash", "base_name": "Arc_Lash", "size": 64,
			"color": Color(0.50, 0.25, 0.80, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Unstable_Rift", "base_name": "Unstable_Rift", "size": 64,
			"color": Color(0.40, 0.15, 0.70, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Cataclysmic_Surge", "base_name": "Cataclysmic_Surge", "size": 64,
			"color": Color(0.60, 0.20, 0.85, 1.0) },
	# Scholar
	{ "folder": "Abilities/Role_Active_Skills/Sharp_Rebuttal", "base_name": "Sharp_Rebuttal", "size": 64,
			"color": Color(0.25, 0.45, 0.75, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Expose_Fallacy", "base_name": "Expose_Fallacy", "size": 64,
			"color": Color(0.20, 0.55, 0.80, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Refutation", "base_name": "Refutation", "size": 64,
			"color": Color(0.30, 0.50, 0.70, 1.0) },
	# Diviner
	{ "folder": "Abilities/Role_Active_Skills/Ill_Omen", "base_name": "Ill_Omen", "size": 64,
			"color": Color(0.30, 0.35, 0.65, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Premonition", "base_name": "Premonition", "size": 64,
			"color": Color(0.35, 0.60, 0.80, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Fateful_Glimpse", "base_name": "Fateful_Glimpse", "size": 64,
			"color": Color(0.40, 0.55, 0.75, 1.0) },
	# Appraiser
	{ "folder": "Abilities/Role_Active_Skills/Sizing_Cut", "base_name": "Sizing_Cut", "size": 64,
			"color": Color(0.80, 0.60, 0.20, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Flaw_Analysis", "base_name": "Flaw_Analysis", "size": 64,
			"color": Color(0.75, 0.50, 0.15, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Full_Appraisal", "base_name": "Full_Appraisal", "size": 64,
			"color": Color(0.85, 0.70, 0.30, 1.0) },
	# Tactician
	{ "folder": "Abilities/Role_Active_Skills/Signal_Strike", "base_name": "Signal_Strike", "size": 64,
			"color": Color(0.30, 0.55, 0.45, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Battle_Orders", "base_name": "Battle_Orders", "size": 64,
			"color": Color(0.25, 0.60, 0.40, 1.0) },
	# Symbiote
	{ "folder": "Abilities/Role_Active_Skills/Spore_Lash", "base_name": "Spore_Lash", "size": 64,
			"color": Color(0.45, 0.55, 0.30, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Symbiotic_Overdrive", "base_name": "Symbiotic_Overdrive", "size": 64,
			"color": Color(0.50, 0.45, 0.25, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Grafted_Flesh", "base_name": "Grafted_Flesh", "size": 64,
			"color": Color(0.40, 0.50, 0.35, 1.0) },
	# Jester
	{ "folder": "Abilities/Role_Active_Skills/Pratfall_Sting", "base_name": "Pratfall_Sting", "size": 64,
			"color": Color(0.75, 0.30, 0.55, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Center_Stage", "base_name": "Center_Stage", "size": 64,
			"color": Color(0.85, 0.35, 0.60, 1.0) },
	# Cultist
	{ "folder": "Abilities/Role_Active_Skills/Profane_Bolt", "base_name": "Profane_Bolt", "size": 64,
			"color": Color(0.45, 0.15, 0.35, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Devour_Blessing", "base_name": "Devour_Blessing", "size": 64,
			"color": Color(0.50, 0.10, 0.30, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Rite_of_Severance", "base_name": "Rite_of_Severance", "size": 64,
			"color": Color(0.40, 0.10, 0.40, 1.0) },
	# Bar Brawler
	{ "folder": "Abilities/Role_Active_Skills/Headbutt", "base_name": "Headbutt", "size": 64,
			"color": Color(0.70, 0.40, 0.20, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Liquid_Courage", "base_name": "Liquid_Courage", "size": 64,
			"color": Color(0.75, 0.45, 0.25, 1.0) },
	# Bloodmage
	{ "folder": "Abilities/Role_Active_Skills/Blood_Bolt", "base_name": "Blood_Bolt", "size": 64,
			"color": Color(0.65, 0.10, 0.15, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Transfusion", "base_name": "Transfusion", "size": 64,
			"color": Color(0.55, 0.15, 0.20, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Tithe_of_Vitality", "base_name": "Tithe_of_Vitality", "size": 64,
			"color": Color(0.60, 0.10, 0.25, 1.0) },
	# Lancer
	{ "folder": "Abilities/Role_Active_Skills/Lance_Thrust", "base_name": "Lance_Thrust", "size": 64,
			"color": Color(0.60, 0.45, 0.30, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Rending_Charge", "base_name": "Rending_Charge", "size": 64,
			"color": Color(0.65, 0.35, 0.20, 1.0) },
	# Plague Doctor
	{ "folder": "Abilities/Role_Active_Skills/Septic_Lance", "base_name": "Septic_Lance", "size": 64,
			"color": Color(0.35, 0.45, 0.25, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Quarantine_Breach", "base_name": "Quarantine_Breach", "size": 64,
			"color": Color(0.30, 0.50, 0.30, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Miasma", "base_name": "Miasma", "size": 64,
			"color": Color(0.25, 0.45, 0.20, 1.0) },
	# Warlord
	{ "folder": "Abilities/Role_Active_Skills/Shield_Slam", "base_name": "Shield_Slam", "size": 64,
			"color": Color(0.35, 0.45, 0.60, 1.0) },
	# Hold the Line reuses Stalwart_Hymn.tres's real hand-authored art (renamed
	# Hold_the_Line.jpg), so it needs no placeholder row here.
	{ "folder": "Abilities/Role_Active_Skills/Brace_for_Impact", "base_name": "Brace_for_Impact", "size": 64,
			"color": Color(0.40, 0.50, 0.65, 1.0) },
	# Chronophage
	{ "folder": "Abilities/Role_Active_Skills/Temporal_Sinkhole", "base_name": "Temporal_Sinkhole", "size": 64,
			"color": Color(0.35, 0.20, 0.50, 1.0) },
	# Emissary
	{ "folder": "Abilities/Role_Active_Skills/Citation", "base_name": "Citation", "size": 64,
			"color": Color(0.60, 0.50, 0.20, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Signed_Writ", "base_name": "Signed_Writ", "size": 64,
			"color": Color(0.65, 0.45, 0.15, 1.0) },
	{ "folder": "Abilities/Role_Active_Skills/Levied_Sanction", "base_name": "Levied_Sanction", "size": 64,
			"color": Color(0.55, 0.40, 0.10, 1.0) },
	# Unassigned zone
	{ "folder": "Abilities/Role_Active_Skills/Weight_of_Law", "base_name": "Weight_of_Law", "size": 64,
			"color": Color(0.50, 0.50, 0.55, 1.0) },
	# Opponent skills (Opponent_Active_Skills)
	{ "folder": "Abilities/Opponent_Active_Skills/Wind_the_Mainspring", "base_name": "Wind_the_Mainspring", "size": 64,
			"color": Color(0.70, 0.55, 0.20, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Overwhelming_Blow", "base_name": "Overwhelming_Blow", "size": 64,
			"color": Color(0.65, 0.30, 0.15, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Rally_the_Crew", "base_name": "Rally_the_Crew", "size": 64,
			"color": Color(0.75, 0.45, 0.20, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Cinder_Spit", "base_name": "Cinder_Spit", "size": 64,
			"color": Color(0.80, 0.35, 0.15, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Vault_Slam", "base_name": "Vault_Slam", "size": 64,
			"color": Color(0.55, 0.35, 0.25, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Sporeburst_Mend", "base_name": "Sporeburst_Mend", "size": 64,
			"color": Color(0.45, 0.60, 0.35, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Flank_Cut", "base_name": "Flank_Cut", "size": 64,
			"color": Color(0.70, 0.25, 0.20, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Breaching_Charge", "base_name": "Breaching_Charge", "size": 64,
			"color": Color(0.65, 0.35, 0.25, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Aimed_Shot", "base_name": "Aimed_Shot", "size": 64,
			"color": Color(0.75, 0.40, 0.30, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/March_Cadence", "base_name": "March_Cadence", "size": 64,
			"color": Color(0.70, 0.50, 0.25, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Cinder_Sermon", "base_name": "Cinder_Sermon", "size": 64,
			"color": Color(0.85, 0.30, 0.15, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Foreclosure", "base_name": "Foreclosure", "size": 64,
			"color": Color(0.55, 0.45, 0.20, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Writ_of_Seizure", "base_name": "Writ_of_Seizure", "size": 64,
			"color": Color(0.60, 0.35, 0.30, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Reliquary_Ward", "base_name": "Reliquary_Ward", "size": 64,
			"color": Color(0.50, 0.40, 0.35, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Inscribe", "base_name": "Inscribe", "size": 64,
			"color": Color(0.65, 0.25, 0.45, 1.0) },
	{ "folder": "Abilities/Opponent_Active_Skills/Inscription_Surge", "base_name": "Inscription_Surge", "size": 64,
			"color": Color(0.70, 0.20, 0.40, 1.0) },
	# Passives (Passives)
	{ "folder": "Abilities/Passives/Ash_Offering", "base_name": "Ash_Offering", "size": 64,
			"color": Color(0.45, 0.35, 0.30, 1.0) },
	{ "folder": "Abilities/Passives/Lien", "base_name": "Lien", "size": 64,
			"color": Color(0.40, 0.35, 0.45, 1.0) },
	{ "folder": "Abilities/Passives/Wardens_Failsafe", "base_name": "Wardens_Failsafe", "size": 64,
			"color": Color(0.35, 0.30, 0.40, 1.0) },
	{ "folder": "Abilities/Passives/Standing_Record", "base_name": "Standing_Record", "size": 64,
			"color": Color(0.50, 0.42, 0.28, 1.0) },
]

# One row per opponent body still awaiting real art. Creatures aren't rarity-tiered, so
# like the skill and status tables each row writes a single flat-color PNG. Rows land
# under CREATURE_ROOT rather than ICON_ROOT, one folder per creature, grouped by
# encounter with a distinct base hue.
#   folder, base_name, size, color
const CREATURE_PLACEHOLDER_TABLE: Array = [
	# Sporeback Pack
	{ "folder": "Spore_Hound", "base_name": "Spore_Hound", "size": 128,
			"color": Color(0.45, 0.55, 0.30, 1.0) },
	{ "folder": "Sporeback_Matron", "base_name": "Sporeback_Matron", "size": 128,
			"color": Color(0.40, 0.60, 0.35, 1.0) },
	# Wake Skimmers
	{ "folder": "Skimmer_Cutthroat", "base_name": "Skimmer_Cutthroat", "size": 128,
			"color": Color(0.20, 0.45, 0.60, 1.0) },
	{ "folder": "Bosun", "base_name": "Bosun", "size": 128,
			"color": Color(0.15, 0.40, 0.55, 1.0) },
	# Ledger Clerks
	{ "folder": "Warded_Clerk", "base_name": "Warded_Clerk", "size": 128,
			"color": Color(0.50, 0.50, 0.55, 1.0) },
	# Plains Outriders
	{ "folder": "Outrider_Lancer", "base_name": "Outrider_Lancer", "size": 128,
			"color": Color(0.65, 0.50, 0.25, 1.0) },
	{ "folder": "War_Drummer", "base_name": "War_Drummer", "size": 128,
			"color": Color(0.60, 0.45, 0.20, 1.0) },
	# Ridge Marksmen
	{ "folder": "Scavenger_Skirmisher", "base_name": "Scavenger_Skirmisher", "size": 128,
			"color": Color(0.55, 0.40, 0.30, 1.0) },
	{ "folder": "Ridge_Marksman", "base_name": "Ridge_Marksman", "size": 128,
			"color": Color(0.50, 0.35, 0.25, 1.0) },
	# Flank Cutter
	{ "folder": "Flank_Cutter", "base_name": "Flank_Cutter", "size": 128,
			"color": Color(0.70, 0.25, 0.20, 1.0) },
	# Line Breaker
	{ "folder": "Plains_Charger", "base_name": "Plains_Charger", "size": 128,
			"color": Color(0.65, 0.35, 0.20, 1.0) },
	{ "folder": "Drover", "base_name": "Drover", "size": 128,
			"color": Color(0.60, 0.40, 0.25, 1.0) },
	# The Ashen Oracle
	{ "folder": "Cinder_Husk", "base_name": "Cinder_Husk", "size": 128,
			"color": Color(0.55, 0.20, 0.15, 1.0) },
	{ "folder": "Ashen_Oracle", "base_name": "Ashen_Oracle", "size": 128,
			"color": Color(0.60, 0.25, 0.15, 1.0) },
	# The Glyphbound Archivist
	{ "folder": "Glyphbound_Archivist", "base_name": "Glyphbound_Archivist", "size": 128,
			"color": Color(0.45, 0.20, 0.55, 1.0) },
	# The Collector of Debts
	{ "folder": "Collector_of_Debts", "base_name": "Collector_of_Debts", "size": 128,
			"color": Color(0.40, 0.35, 0.15, 1.0) },
	{ "folder": "Warded_Notary", "base_name": "Warded_Notary", "size": 128,
			"color": Color(0.45, 0.40, 0.20, 1.0) },
	# The Warden of the Reliquary
	{ "folder": "Vault_Warden", "base_name": "Vault_Warden", "size": 128,
			"color": Color(0.35, 0.35, 0.45, 1.0) },
	{ "folder": "Reliquary_Core", "base_name": "Reliquary_Core", "size": 128,
			"color": Color(0.30, 0.30, 0.50, 1.0) },
]

# Rarity tier order, tint color, and blend strength (how far the base hue shifts
# toward the tint). Blend strength increases with rarity.
const RARITY_TINTS: Array = [
	{ "name": "Uncommon", "tint": Color(0.20, 0.80, 0.30, 1.0), "strength": 0.15 },
	{ "name": "Rare", "tint": Color(0.20, 0.50, 0.90, 1.0), "strength": 0.30 },
	{ "name": "Epic", "tint": Color(0.60, 0.20, 0.85, 1.0), "strength": 0.45 },
	{ "name": "Legendary", "tint": Color(0.95, 0.55, 0.10, 1.0), "strength": 0.60 },
]


func _run() -> void:
	var written_count: int = 0
	var skipped_count: int = 0
	for family_row in REAGENT_FAMILY_TABLE:
		var folder_path: String = "%s/%s" % [ICON_ROOT, family_row["folder"]]
		var make_result: int = DirAccess.make_dir_recursive_absolute(folder_path)
		if make_result != OK and not DirAccess.dir_exists_absolute(folder_path):
			push_error("Could not create folder: %s" % folder_path)
			continue
		for rarity_row in RARITY_TINTS:
			var path: String = "%s/%s_%s.png" % [folder_path, family_row["base_name"], rarity_row["name"]]
			if not OVERWRITE and FileAccess.file_exists(path):
				print("skip (exists): %s" % path)
				skipped_count += 1
				continue
			var color: Color = _rarity_tinted_color(family_row["color"], rarity_row)
			var size: int = family_row["size"]
			var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
			image.fill(color)
			var save_result: int = image.save_png(path)
			if save_result != OK:
				push_error("Failed to write: %s" % path)
				continue
			print("wrote: %s (%dx%d)" % [path, size, size])
			written_count += 1
	var status_counts: Vector2i = _write_flat_icon_table(STATUS_EFFECT_TABLE)
	written_count += status_counts.x
	skipped_count += status_counts.y
	var skill_counts: Vector2i = _write_flat_icon_table(SKILL_ICON_TABLE)
	written_count += skill_counts.x
	skipped_count += skill_counts.y
	var creature_counts: Vector2i = _write_flat_icon_table(CREATURE_PLACEHOLDER_TABLE, CREATURE_ROOT)
	written_count += creature_counts.x
	skipped_count += creature_counts.y
	print("---")
	print("Done. %d written, %d skipped." % [written_count, skipped_count])


## Writes one flat-color PNG per row of a non-rarity-tiered table, creating folders and
## honoring the skip-if-exists guard. Returns the written and skipped counts as (x, y).
func _write_flat_icon_table(table: Array, output_root: String = ICON_ROOT) -> Vector2i:
	var written: int = 0
	var skipped: int = 0
	for row in table:
		var folder_path: String = "%s/%s" % [output_root, row["folder"]]
		var make_result: int = DirAccess.make_dir_recursive_absolute(folder_path)
		if make_result != OK and not DirAccess.dir_exists_absolute(folder_path):
			push_error("Could not create folder: %s" % folder_path)
			continue
		var path: String = "%s/%s.png" % [folder_path, row["base_name"]]
		if not OVERWRITE and FileAccess.file_exists(path):
			print("skip (exists): %s" % path)
			skipped += 1
			continue
		var size: int = row["size"]
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		image.fill(row["color"])
		var save_result: int = image.save_png(path)
		if save_result != OK:
			push_error("Failed to write: %s" % path)
			continue
		print("wrote: %s (%dx%d)" % [path, size, size])
		written += 1
	return Vector2i(written, skipped)


## Blends a family's base hue toward a rarity tier's tint color by that tier's
## blend strength, so every reagent family reads as one hue family across rarities
## while still visibly distinguishing rarity at a glance.
func _rarity_tinted_color(base_color: Color, rarity_row: Dictionary) -> Color:
	var tint: Color = rarity_row["tint"]
	var strength: float = rarity_row["strength"]
	return base_color.lerp(tint, strength)
