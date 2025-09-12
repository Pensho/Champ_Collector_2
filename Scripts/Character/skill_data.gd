class_name Skill extends Resource

const Types = preload("res://Scripts/common_enums.gd")

@export var name: String = "New Skill"
@export var description: String = ""
@export var icon_path: String = ""
@export var target: Types.Skill_Target
