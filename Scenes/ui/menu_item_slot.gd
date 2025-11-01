class_name MenuItemSlot extends Control

@onready var texture_rect: TextureRect = $TextureRect/TextureRect
@onready var button: Button = $TextureRect/Button
@export var _ID: int = -1
@onready var level: Label = $TextureRect/Label

func ConnectButton(p_callback: Callable) -> void:
	button.connect("button_up", p_callback.bind(_ID))

func SetHeldObjectTexture(p_texture: Texture) -> void:
	texture_rect.texture = p_texture
