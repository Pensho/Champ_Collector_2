class_name RewardItemSlotUI extends Control

@export var _texture_rect: TextureRect
@export var _label_count: Label
@export var _tooltip: ToolTip

func SetTexture(p_texture: Texture) -> void:
	_texture_rect.texture = p_texture

func SetCount(p_text: String) -> void:
	_label_count.visible = not p_text.is_empty()
	_label_count.text = p_text

func SetToolTip(p_title: String, p_description: String) -> void:
	_tooltip.title_text = p_title
	_tooltip.description_text = p_description
