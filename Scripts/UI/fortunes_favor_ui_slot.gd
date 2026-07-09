class_name FortunesFavorUISlot extends Control

@export var _main_slot: ResourceUISlot
@export var _toggle_button: Button
@export var _dropdown: Control
@export var _tier_slots: Array[ResourceUISlot]

func _ready() -> void:
	_dropdown.visible = false
	_toggle_button.pressed.connect(_OnTogglePressed)

func _OnTogglePressed() -> void:
	_dropdown.visible = not _dropdown.visible

func SetMainSlot(p_text: String, p_texture: Texture, p_tooltip_title: String, p_tooltip_description: String) -> void:
	_main_slot.SetText(p_text)
	_main_slot.SetTexture(p_texture)
	_main_slot.SetToolTip(p_tooltip_title, p_tooltip_description)

func SetTierSlot(
		p_index: int,
		p_text: String,
		p_texture: Texture,
		p_tooltip_title: String,
		p_tooltip_description: String) -> void:
	var slot: ResourceUISlot = _tier_slots[p_index]
	slot.SetText(p_text)
	slot.SetTexture(p_texture)
	slot.SetToolTip(p_tooltip_title, p_tooltip_description)
