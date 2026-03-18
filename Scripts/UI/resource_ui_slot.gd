class_name ResourceUISlot extends Control

@export var _texture: TextureRect
@export var _label: Label

func SetTexture(p_texture: Texture) -> void:
	_texture.texture = p_texture

func SetText(p_text: String) -> void:
	_label.text = p_text
