class_name CharacterRepresentation extends Node2D

@warning_ignore_start("unused_private_class_variable")
@onready var _character_texture: TextureRect = $TextureRect
@onready var _lifebar: ProgressBar = $ProgressBar
@onready var _lifebar_text: Label = $ProgressBar/Label
@onready var _level: Label = $ColorRect/Label
@warning_ignore_restore("unused_private_class_variable")
const TRAIT_UI_ELEMENT_BLANK = preload("uid://cdwqpx4sgt42a")

signal battle_target_selected(p_target_ID: int)
@export var _trait_icons: Array[TextureRect]
@export var _trait_tooltips: Array[ToolTip]
@export var _target_ID: int = -1
@export var _status_effect_textures: Array[TextureRect]

var _status_effect: Dictionary[int, int]
var _status_effect_counter: int = 0

func _on_button_target_button_up() -> void:
	battle_target_selected.emit(_target_ID)

func AddStatusEffect(p_effect_texture: Texture, p_duration: int) -> int:
	for slot in _status_effect_textures.size():
		if (not _status_effect_textures[slot].is_visible_in_tree()):
			_status_effect_textures[slot].texture = p_effect_texture
			_status_effect[_status_effect_counter] = slot
			_status_effect_counter += 1
			_status_effect_textures[slot].show()
			SetStatusEffectDuration(slot, p_duration)
			return _status_effect_counter - 1
	print("character_battle_repr.gd/AddStatusEffect: Failed to add status effect!")
	return -1

func SetStatusEffectDuration(p_effect_ID: int, p_duration: int) -> void:
	if(_status_effect.has(p_effect_ID)):
		_status_effect_textures[_status_effect[p_effect_ID]].get_child(0).text = str(p_duration)
	else:
		print("No status effect found at ID: ", p_effect_ID)

func RemoveStatusEffects(p_effect_IDs: Array[int]) -> void:
	for effect_ID in p_effect_IDs:
		_status_effect_textures[_status_effect[effect_ID]].hide()

func ClearAllStatusEffects() -> void:
	for textRect in _status_effect_textures:
		if(null != textRect.texture):
			textRect.texture = null
			textRect.hide()

func SetTraitElement(p_texture: Texture, p_slot: int) -> void:
	if(p_slot < 0 or p_slot >= _trait_icons.size()):
		print("Trying to draw character_repr trait elements out of range; ", p_slot)
	_trait_icons[p_slot].texture = p_texture
	_trait_icons[p_slot].show()

func RemoveTraitElement(p_slot: int) -> void:
	if(p_slot < 0 or p_slot >= _trait_icons.size()):
		print("Trying to draw character_repr trait elements out of range; ", p_slot)
	_trait_icons[p_slot].hide()

func SetBlankTraitElement(p_slot: int) -> void:
	if(p_slot < 0 or p_slot >= _trait_icons.size()):
		print("Trying to draw character_repr trait elements out of range; ", p_slot)
	_trait_icons[p_slot].texture = TRAIT_UI_ELEMENT_BLANK
	_trait_icons[p_slot].show()

func SetTraitElementToolTip(p_title: String, p_body: String, p_slot: int) -> void:
	if(p_slot < 0 or p_slot >= _trait_icons.size()):
		print("Trying to draw character_repr trait elements out of range; ", p_slot)
	_trait_tooltips[p_slot].title_text = p_title
	_trait_tooltips[p_slot].description_text = p_body
