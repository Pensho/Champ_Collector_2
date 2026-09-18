class_name TallyBoardSlot extends Control

@export var _ID: int = -1
@export var _tooltip: ToolTip

var _entry: Dictionary

@onready var _label_ribbon: Label = $Label_Ribbon
@onready var _texture_rect_icon: TextureRect = $TextureRect_Icon
@onready var _texture_rect_icon_darken: TextureRect = $TextureRect_IconDarken
@onready var _content: Control = $Content
@onready var _label_name: Label = $Content/Label_Name
@onready var _texture_rect_tally: TextureRect = $Content/TextureRect_Tally
@onready var _label_price: Label = $Content/Label_Price
@onready var _button_buy: Button = $Content/Button_Buy

func Setup(p_entry: Dictionary) -> void:
	_entry = p_entry
	var preset: CharacterPreset = load(p_entry["preset_path"])
	_texture_rect_icon.texture = TextureCache.GetHeadshot(preset._texture, preset._headshot_region)
	_texture_rect_icon_darken.texture = _texture_rect_icon.texture
	_label_name.text = preset._name
	_texture_rect_tally.texture = ResourceHandler.TALLY_TEXTURE
	_texture_rect_icon.material.set("shader_parameter/color", RarityColors.GetFill(p_entry["rarity"]))
	_label_ribbon.text = Types.RarityName(p_entry["rarity"])
	_tooltip.title_text = preset._name
	_tooltip.description_text = "Recruits with a randomly rolled Nature."
	ClearSoldOut()

func ClearSoldOut() -> void:
	_content.modulate.a = 1.0
	_texture_rect_icon_darken.visible = false
	_button_buy.text = "Buy"
	_button_buy.disabled = false
	_label_price.text = str(_entry["price"])

func SetSoldOut(p_sold_out: bool) -> void:
	if(not p_sold_out):
		return
	_content.modulate.a = 0.4
	_texture_rect_icon_darken.visible = true
	_button_buy.text = "Sold Out"
	_button_buy.disabled = true

func ConnectButton(p_callback: Callable) -> void:
	_button_buy.connect("button_up", p_callback.bind(_ID))
