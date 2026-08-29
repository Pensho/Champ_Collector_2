class_name MenuItemSlot extends Control

@export var _ID: int = -1
@export var _tooltip: ToolTip

@onready var texture_rect: TextureRect = $TextureRect/TextureRect
@onready var button: Button = $TextureRect/Button
@onready var level: Label = $TextureRect/Label

func ConnectButton(p_callback: Callable) -> void:
	button.connect("button_up", p_callback.bind(_ID))

func SetToolTip(p_title: String, p_description: String) -> void:
	_tooltip.title_text = p_title
	_tooltip.description_text = p_description
	_tooltip.visible = true

func ClearToolTip() -> void:
	_tooltip.visible = false

func SetHeldObjectTexture(p_texture: Texture) -> void:
	texture_rect.texture = p_texture

func SetHeldObjectModulate(p_color: Color) -> void:
	self.modulate = p_color

func SetTextureOutline(p_rarity: Types.Rarity) -> void:
	var col: Color = Color(0.0, 0.0, 0.0, 0.0)
	match p_rarity:
		Types.Rarity.Common:
			col = Color(0.384, 0.384, 0.384, 1.0)
		Types.Rarity.Uncommon:
			col = Color(0.0, 0.544, 0.313, 1.0)
		Types.Rarity.Rare:
			col = Color(0.003, 0.152, 0.701, 1.0)
		Types.Rarity.Epic:
			col = Color(0.413, 0.0, 0.484, 1.0)
		Types.Rarity.Legendary:
			col = Color(0.651, 0.381, 0.0, 1.0)
		_:
			col = Color(0.0, 0.0, 0.0, 0.0)
	texture_rect.material.set("shader_parameter/color", col)
