class_name CharacterRepresentation extends Node2D

@warning_ignore_start("unused_private_class_variable")
@onready var _character_texture: TextureRect = $TextureRect
@onready var _lifebar: ProgressBar = $ProgressBar
@onready var _lifebar_text: Label = $ProgressBar/Label
@onready var _level: Label = $ColorRect/Label

@export var _target_ID: int = -1
@warning_ignore_restore("unused_private_class_variable")

signal battle_target_selected(p_target_ID: int)

func _on_button_target_button_up() -> void:
	battle_target_selected.emit(_target_ID)
