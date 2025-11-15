class_name Skill extends Resource

const Types = preload("res://Scripts/common_enums.gd")
const Statuses = preload("res://Scripts/status_effects.gd")

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

@export var buffs: Dictionary[Types.Skill_Target, Types.Buff_Type]
@export var debuffs: Dictionary[Types.Skill_Target, Types.Debuff_Type]
