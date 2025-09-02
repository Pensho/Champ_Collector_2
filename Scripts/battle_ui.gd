class_name BattleUI extends Control

@onready var _turn_bar: Panel = $Camera2D/PlayerInfoBox

@export var _char_turns: Array[TextureRect]

func _on_skill_1_button_up() -> void:
	print("_on_skill_1_button_up")

func _on_skill_2_button_up() -> void:
	print("_on_skill_2_button_up")

func _on_skill_3_button_up() -> void:
	print("_on_skill_3_button_up")
