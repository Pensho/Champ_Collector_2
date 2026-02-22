class_name CharacterDamageResultUI
extends Control

@export var _name: Label
@export var _texture: TextureRect
@export var _damage_bar: ProgressBar
@export var _damage_label: Label

func SetName(p_name: String) -> void:
	_name.text = p_name

func SetTexture(p_texture: Texture) -> void:
	_texture.texture = p_texture

func SetDamageDealt(p_damage: int, p_total_damage_dealt) -> void:
	_damage_bar.value = p_damage
	_damage_bar.max_value = p_total_damage_dealt
	_damage_label.text = str(p_damage)
	
	var style_box: StyleBoxFlat = _damage_bar.get_theme_stylebox("fill")
	
	var red: float = 1.0 - (float(p_damage) / float(p_total_damage_dealt))
	var green: float = float(p_damage) / float(p_total_damage_dealt)
	style_box.bg_color = Color(red, green, 0.0, 1.0)
	print(style_box.bg_color)
	_damage_bar.add_theme_stylebox_override("fill", style_box)
