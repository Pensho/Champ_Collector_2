class_name BattleUI extends Control

@warning_ignore_start("unused_private_class_variable")
@export var _char_turns: Array[TextureRect]
@onready var _skill_button_1: Button = $Camera2D/Skill_1
@onready var _skill_button_2: Button = $Camera2D/Skill_2
@onready var _skill_button_3: Button = $Camera2D/Skill_3
@warning_ignore_restore("unused_private_class_variable")

signal battle_skill_selected(p_skill_ID: int)

func SetSkill1Texture(p_texture_path: String) -> void:
	_skill_button_1.icon = load(p_texture_path)

func SetSkill2Texture(p_texture_path: String) -> void:
	_skill_button_2.icon = load(p_texture_path)

func SetSkill3Texture(p_texture_path: String) -> void:
	_skill_button_3.icon = load(p_texture_path)

func _on_skill_1_button_up() -> void:
	battle_skill_selected.emit(0)

func _on_skill_2_button_up() -> void:
	battle_skill_selected.emit(1)

func _on_skill_3_button_up() -> void:
	battle_skill_selected.emit(2)
