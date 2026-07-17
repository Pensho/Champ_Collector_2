class_name ReagentData extends Resource

## Data-driven definition of one reagent (Concept_Document.md 3.3.3), one rarity tier
## per resource. Reagent effects scale with rarity only, never with the consumer's
## attributes, so this resource deliberately carries no attribute-hook fields. Looked
## up through ReagentRegistry.

enum EffectKind {
	Attribute_Increase,        # magnitude: percent added to affected_attribute, battle-long
	Heal,                      # magnitude: percent of target's max Health
	Remove_Debuffs,            # magnitude: max debuffs removed from target (int count)
	Destroy_Enemy_Buffs,       # magnitude: max buffs destroyed on target (int count)
	Reduce_Cooldown,           # magnitude: turns removed from every skill on target with cooldown_left > 0
	Turn_Bar_Reset,            # magnitude: percent the consumer's turn bar resets to after their turn, instead of 0
	Clear_Zone,                # binary: clears the targeted zone section
	Random_Attribute_Increase, # magnitude: percent added to one random primary attribute, battle-long
	# Health_Cost_Damage_Bonus: magnitude is percent of consumer's max Health dealt as
	# self-damage; secondary_magnitude is the percent battle-long bonus to damage dealt.
	Health_Cost_Damage_Bonus,
}

enum TargetKind
{
	Self_Target,
	One_Ally,
	One_Enemy,
	Zone_Section,
}

@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var rarity: Types.Rarity
@export var binary: bool = false
@export var effect_kind: EffectKind
@export var target_kind: TargetKind
# Attribute_Increase / Random_Attribute_Increase only. Random_Attribute_Increase rolls
# among the primary attributes at consumption time; this field is left at its default
# and ignored.
@export var affected_attribute: Types.Attribute
# See EffectKind above for per-kind units. 0.0 for binary reagents.
@export var magnitude: float = 0.0
# Health_Cost_Damage_Bonus only: the battle-long damage-dealt bonus percent. 0.0 otherwise.
@export var secondary_magnitude: float = 0.0
