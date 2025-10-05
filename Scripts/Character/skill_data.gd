class_name Skill extends Resource

const Types = preload("res://Scripts/common_enums.gd")

@export var name: String = "New Skill"
@export var description: String = ""
@export var icon_path: String = ""
@export var target: Types.Skill_Target

@export var turn_effect: int
@export var damage_scaling: Dictionary[Types.Attribute, float]
@export var cooldown: int = 0

@export var skill_type: Types.Skill_Type
@export var defense_ignore_factor: float = 1.0
