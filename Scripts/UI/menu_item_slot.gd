class_name MenuItemSlot extends Control

const Types = preload("uid://bkpa0hv70oydy")

@onready var texture_rect: TextureRect = $TextureRect/TextureRect
@onready var button: Button = $TextureRect/Button
@export var _ID: int = -1
@onready var level: Label = $TextureRect/Label

func ConnectButton(p_callback: Callable) -> void:
	button.connect("button_up", p_callback.bind(_ID))

func SetHeldObjectTexture(p_texture: Texture) -> void:
	texture_rect.texture = p_texture

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
		Types.Rarity.Relic:
			col = Color(0.606, 0.0, 0.0, 1.0)
		_:
			col = Color(0.0, 0.0, 0.0, 0.0)
	texture_rect.material.set("shader_parameter/color", col)
