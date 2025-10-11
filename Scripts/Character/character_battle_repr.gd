class_name CharacterRepresentation extends Node2D

signal battle_target_selected(p_target_ID: int)

@warning_ignore_start("unused_private_class_variable")
@onready var _character_texture: TextureRect = $TextureRect
@onready var _lifebar: ProgressBar = $ProgressBar
@onready var _lifebar_text: Label = $ProgressBar/Label
@onready var _level: Label = $ColorRect/Label

@export var _target_ID: int = -1
@warning_ignore_restore("unused_private_class_variable")

@export var _status_effect_textures: Array[TextureRect]

var _status_effect: Dictionary[int, int]
var _status_effect_counter: int = 0

func _on_button_target_button_up() -> void:
	battle_target_selected.emit(_target_ID)

func AddStatusEffect(p_effect_path: String) -> int:
	for slot in _status_effect_textures.size():
		if (null == _status_effect_textures[slot].texture):
			_status_effect_textures[slot].texture = load(p_effect_path)
			_status_effect[_status_effect_counter] = slot
			_status_effect_counter += 1
			_status_effect_textures[slot].show()
			return _status_effect_counter - 1
	print("character_battle_repr.gd/AddStatusEffect: Failed to add status effect!")
	return -1

func RemoveStatusEffects(p_effect_IDs: Array[int]) -> void:
	for effect_ID in p_effect_IDs:
		_status_effect_textures[_status_effect[effect_ID]].texture = null
		_status_effect_textures[_status_effect[effect_ID]].hide()

func ClearStatusEffects() -> void:
	for textRect in _status_effect_textures:
		if(null != textRect.texture):
			textRect.texture = null
			textRect.hide()
