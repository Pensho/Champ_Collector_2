class_name ShopSlot extends Control

const SECONDS_PER_DAY: int = 86400
const SECONDS_PER_HOUR: int = 3600
const SECONDS_PER_MINUTE: int = 60

@export var _ID: int = -1
@export var _tooltip: ToolTip

var _entry: Dictionary

@onready var _label_category: Label = $Label_Category
@onready var _label_ribbon: Label = $Label_Ribbon
@onready var _texture_rect_icon: TextureRect = $TextureRect_Icon
@onready var _texture_rect_icon_darken: TextureRect = $TextureRect_IconDarken
@onready var _label_cooldown: Label = $Label_Cooldown
@onready var _content: Control = $Content
@onready var _label_name: Label = $Content/Label_Name
@onready var _texture_rect_silver: TextureRect = $Content/TextureRect_Silver
@onready var _label_price: Label = $Content/Label_Price
@onready var _button_buy: Button = $Content/Button_Buy

func Setup(p_entry: Dictionary) -> void:
	_entry = p_entry
	_label_category.text = _CategoryName(p_entry["category"])
	_texture_rect_icon.texture = _IconFor(p_entry)
	_texture_rect_icon_darken.texture = _texture_rect_icon.texture
	_label_name.text = _NameFor(p_entry)
	_texture_rect_silver.texture = ResourceHandler.SILVER_COIN_TEXTURE
	_texture_rect_icon.material.set("shader_parameter/color", _RarityColor(p_entry["rarity"]))
	_SetRarityLabel(p_entry)
	_tooltip.title_text = _label_name.text
	ClearSoldOut()

func ClearSoldOut() -> void:
	_content.modulate.a = 1.0
	_texture_rect_icon_darken.visible = false
	_label_cooldown.visible = false
	_button_buy.text = "Buy"
	_button_buy.disabled = false
	_label_price.text = str(_entry["price"])
	_tooltip.description_text = _DescriptionFor(_entry)

func SetSoldOut(p_sold_out: bool) -> void:
	if(not p_sold_out):
		return
	_content.modulate.a = 0.4
	_texture_rect_icon_darken.visible = true
	_button_buy.text = "Sold Out"
	_button_buy.disabled = true

func SetFavorCooldownDisplay(p_seconds_left: int) -> void:
	SetSoldOut(true)
	_label_price.text = ""
	_label_cooldown.text = _FormatCooldown(p_seconds_left) + " left"
	_label_cooldown.visible = true

func _FormatCooldown(p_seconds_left: int) -> String:
	if(p_seconds_left >= SECONDS_PER_DAY):
		@warning_ignore("integer_division")
		var days: int = (p_seconds_left + SECONDS_PER_DAY - 1) / SECONDS_PER_DAY
		return str(days) + (" day" if days == 1 else " days")
	@warning_ignore("integer_division")
	var hours: int = p_seconds_left / SECONDS_PER_HOUR
	@warning_ignore("integer_division")
	var minutes: int = (p_seconds_left % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE
	return str(hours) + "h " + str(minutes) + "m"

func ConnectButton(p_callback: Callable) -> void:
	_button_buy.connect("button_up", p_callback.bind(_ID))

func _SetRarityLabel(p_entry: Dictionary) -> void:
	var has_rarity: bool = (
			p_entry["category"] == Types.Category.Gear
			or p_entry["category"] == Types.Category.Reagent)
	_label_ribbon.visible = has_rarity
	if(not has_rarity):
		return
	_label_ribbon.text = Types.RarityName(p_entry["rarity"])

func _CategoryName(p_category: Types.Category) -> String:
	match p_category:
		Types.Category.Gear:
			return "Gear"
		Types.Category.Reagent:
			return "Reagent"
		Types.Category.Supplies:
			return "Supplies"
		Types.Category.FortunesFavor:
			return "Fortune's Favor"
	return ""

func _NameFor(p_entry: Dictionary) -> String:
	match p_entry["category"]:
		Types.Category.Gear:
			return EquipmentPresetRegistry.Get(p_entry["payload"])._name
		Types.Category.Reagent:
			return ReagentRegistry.Get(p_entry["payload"]).display_name
		Types.Category.Supplies:
			return "Supplies Bundle"
		Types.Category.FortunesFavor:
			return "Fortune's Favor"
	return ""

func _IconFor(p_entry: Dictionary) -> Texture2D:
	match p_entry["category"]:
		Types.Category.Gear:
			return load(EquipmentPresetRegistry.Get(p_entry["payload"])._texture_path)
		Types.Category.Reagent:
			return ReagentRegistry.Get(p_entry["payload"]).icon
		Types.Category.Supplies:
			return ResourceHandler.SUPPLIES_TEXTURE
		Types.Category.FortunesFavor:
			return ResourceHandler.FORTUNES_FAVOR_BONE_1
	return null

func _DescriptionFor(p_entry: Dictionary) -> String:
	match p_entry["category"]:
		Types.Category.Gear:
			return _GearDescription(p_entry)
		Types.Category.Reagent:
			return ReagentRegistry.Get(p_entry["payload"]).description
		Types.Category.Supplies:
			return "Grants " + str(p_entry["amount"]) + " Supplies."
		Types.Category.FortunesFavor:
			return "Used to recruit new champions."
	return ""

func _GearDescription(p_entry: Dictionary) -> String:
	var preset: EquipmentPreset = EquipmentPresetRegistry.Get(p_entry["payload"])
	var lines: Array[String] = []
	for attribute_name in p_entry["attributes"].keys():
		lines.append(attribute_name + " +" + str(p_entry["attributes"][attribute_name]))
	if(lines.is_empty()):
		return Types.Slot.keys()[preset._slot] + " with no attribute bonus."
	return Types.Slot.keys()[preset._slot] + "\n" + "\n".join(lines)

func _RarityColor(p_rarity: int) -> Color:
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
	return col
