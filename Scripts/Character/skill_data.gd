class_name Skill extends Resource

const Types = preload("res://Scripts/common_enums.gd")

@export var name: String = "New Skill"
@export var description: String = ""
@export var icon_path: String = ""
@export var target: Types.Skill_Target

@export var turn_effect: int
@export var damage_scaling: Dictionary[Types.Attribute, float]
# cooldown is the amount of turns until the skill can be used again.
@export var cooldown: int = 0

@export var skill_type: Types.Skill_Type
# defense_ignore_factor goes between 0.0 - 1.0
# lower the value = more damage that bypasses defense
@export var defense_ignore_factor: float = 1.0
