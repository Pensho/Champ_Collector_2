class_name BattleUI extends Control

@warning_ignore_start("unused_private_class_variable")
@export var _char_turns: Array[TextureRect]
@warning_ignore_restore("unused_private_class_variable")

func _on_skill_1_button_up() -> void:
	print("_on_skill_1_button_up")

func _on_skill_2_button_up() -> void:
	print("_on_skill_2_button_up")

func _on_skill_3_button_up() -> void:
	print("_on_skill_3_button_up")
