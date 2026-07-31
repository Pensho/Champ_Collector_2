class_name Skill extends Resource

const Statuses = preload("uid://bp3pvvar4437")

@export var name: String = "New Skill"
@export var description: String = ""
@export var icon_path: String = ""
@export var target: Types.Skill_Target

# turn_effect is used as a percentage. -1.0 - 1.0
@export var turn_effect: float
@export var damage_scaling: Dictionary[Types.Attribute, float]
# cooldown is the amount of turns until the skill can be used again.
@export var cooldown: int = 0
@export var duration: int = 0

@export var skill_type: Types.Skill_Type
# defense_ignore_factor goes between 0.0 - 1.0
# lower the value = more damage that bypasses defense
@export var defense_ignore_factor: float = 1.0

@export var buffs: Dictionary[Types.Skill_Target, Array]
@export var debuffs: Dictionary[Types.Skill_Target, Array]

# Fraction of max Health each target group gains (positive) or pays (negative).
@export var health_change: Dictionary[Types.Skill_Target, float]
# Attribute-scaled healing per target group: group -> Dictionary[Types.Attribute, float].
@export var heal_scaling: Dictionary[Types.Skill_Target, Dictionary]
# Multiplier turning the Health the caster paid this cast into the granted Barrier's pool.
@export var barrier_from_health_paid: float = 0.0

var cooldown_left: int = 0
