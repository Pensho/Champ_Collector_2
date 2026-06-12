class_name ResourceUISlot extends Control

@export var _texture: TextureRect
@export var _label: Label
@export var _tooltip: ToolTip

func SetTexture(p_texture: Texture) -> void:
	_texture.texture = p_texture

func SetText(p_text: String) -> void:
	_label.text = p_text

func SetToolTip(p_title: String, p_description: String) -> void:
	_tooltip.title_text = p_title
	_tooltip.description_text = p_description
