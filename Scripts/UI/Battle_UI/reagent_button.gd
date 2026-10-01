class_name ReagentButton extends Button

const SPENT_MODULATE: Color = Color(0.35, 0.35, 0.35, 1.0)

@export var _rarity_backdrop: ColorRect
@export var _icon_rect: TextureRect
@export var _frame: Panel

@onready var _tooltip: ToolTip = $Control

func SetReagentIcon(p_texture: Texture2D, p_rarity: Types.Rarity) -> void:
	_icon_rect.texture = p_texture
	var fill: Color = RarityColors.GetFill(p_rarity)
	_rarity_backdrop.material.set_shader_parameter("rarity_color", fill)
	_frame.self_modulate = Color(fill.r * 1.8, fill.g * 1.8, fill.b * 1.8, fill.a)

func SetToolTip(p_title: String, p_description: String) -> void:
	_tooltip.title_text = p_title
	_tooltip.description_text = p_description

func MarkSpent() -> void:
	self.modulate = SPENT_MODULATE
	self.disabled = true

func ClearSpent() -> void:
	self.modulate = Color.WHITE
	self.disabled = false
