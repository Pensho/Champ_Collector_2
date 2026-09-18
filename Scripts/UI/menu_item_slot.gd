class_name MenuItemSlot extends Control

const PIP_FILLED_TEXTURE = preload("uid://ehuiuw7sp7b1")
const PIP_EMPTY_TEXTURE = preload("uid://b5din3anosuf2")

@export var _ID: int = -1
@export var _tooltip: ToolTip

@export var texture_rect: TextureRect
@export var button: Button
@export var level: Label
@export var _renown_pips_row: HBoxContainer
@export var _renown_pips: Array[TextureRect]
@export var _rarity_backdrop: ColorRect
@export var _frame: TextureRect

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

func ClearRarityBackdrop() -> void:
	_rarity_backdrop.material.set_shader_parameter("rarity_color", RarityColors.UNKNOWN)

func SetRarityBackdrop(p_rarity: Types.Rarity) -> void:
	_rarity_backdrop.material.set_shader_parameter("rarity_color", RarityColors.GetFill(p_rarity))
	var fill: Color = RarityColors.GetFill(p_rarity)
	_frame.self_modulate = Color(fill.r * 1.8, fill.g * 1.8, fill.b * 1.8, fill.a)
