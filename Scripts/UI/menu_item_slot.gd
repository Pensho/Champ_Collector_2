class_name MenuItemSlot extends Control

const PIP_FILLED_TEXTURE = preload("uid://ehuiuw7sp7b1")
const PIP_EMPTY_TEXTURE = preload("uid://b5din3anosuf2")

@export var _ID: int = -1
@export var _tooltip: ToolTip

@onready var texture_rect: TextureRect = $TextureRect/TextureRect
@onready var button: Button = $TextureRect/Button
@onready var level: Label = $TextureRect/Label
@onready var _renown_pips_row: HBoxContainer = $TextureRect/HBoxContainer_Renown_Pips
@onready var _renown_pips: Array[TextureRect] = [
	$TextureRect/HBoxContainer_Renown_Pips/Pip_0,
	$TextureRect/HBoxContainer_Renown_Pips/Pip_1,
	$TextureRect/HBoxContainer_Renown_Pips/Pip_2,
	$TextureRect/HBoxContainer_Renown_Pips/Pip_3,
	$TextureRect/HBoxContainer_Renown_Pips/Pip_4,
]

func SetRenownRank(p_rank: int) -> void:
	_renown_pips_row.show()
	for i in _renown_pips.size():
		_renown_pips[i].texture = PIP_FILLED_TEXTURE if i < p_rank else PIP_EMPTY_TEXTURE

func ClearRenownPips() -> void:
	_renown_pips_row.hide()

func ConnectButton(p_callback: Callable) -> void:
	for connection in button.get_signal_connection_list("button_up"):
		button.disconnect("button_up", connection["callable"])
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
