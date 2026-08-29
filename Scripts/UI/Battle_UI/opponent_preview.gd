class_name OpponentPreview extends Control

@export var _label_name: Label
@export var _texture_rect: TextureRect
@export var _tooltip: ToolTip

func Setup(p_preset: CharacterPreset) -> void:
	visible = true
	_label_name.text = p_preset._name
	_texture_rect.texture = TextureCache.Get(p_preset._texture)
	_tooltip.title_text = p_preset._name
	_tooltip.description_text = p_preset._thematic_hint
