class_name ShopMenu extends Control

const BUTTON_WITH_OPTIONS_SCENE: PackedScene = preload("uid://c7smqpmfvs0ih")
const SHOP_SLOT_SCENE: PackedScene = preload("res://Scenes/ui/Shop_Slot.tscn")

var _self_context: ContextContainer
var _confirm_option: ButtonWithOptions
var _insufficient_option: ButtonWithOptions
var _result_option: ButtonWithOptions
var _pending_slot_index: int = -1
var _favor_slot: ShopSlot

@onready var _background: TextureRect = $Background
@onready var _texture_rect_shopkeeper: TextureRect = $TextureRect_Shopkeeper
@onready var _label_restock: Label = $Label_Restock
@onready var _grid_container: GridContainer = $GridArea/GridContainer

func Init(p_context_container: ContextContainer) -> void:
	_self_context = p_context_container

	var background_path: String = p_context_container._arguments.get("Background_Texture", "")
	if(not background_path.is_empty()):
		_background.texture = load(background_path)

	var shopkeeper_path: String = p_context_container._arguments.get("Shopkeeper_Texture", "")
	if(not shopkeeper_path.is_empty()):
		_texture_rect_shopkeeper.texture = load(shopkeeper_path)

	_confirm_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_confirm_option)
	_confirm_option.SetLeftButton("Buy", _on_confirm_buy)
	_confirm_option.position = Vector2i((get_viewport_rect().size * 0.5) - (_confirm_option.GetSize() * 0.5))
	_confirm_option.hide()

	_insufficient_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_insufficient_option)
	_insufficient_option.SetText("Not Enough Silver", "You don't have enough Silver for this purchase.")
	_insufficient_option.position = (
			Vector2i((get_viewport_rect().size * 0.5) - (_insufficient_option.GetSize() * 0.5)))
	_insufficient_option.hide()

	_result_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_result_option)
	_result_option.position = Vector2i((get_viewport_rect().size * 0.5) - (_result_option.GetSize() * 0.5))
	_result_option.hide()

func _ready() -> void:
	var shop: ShopHandler = main.GetInstance()._shop
	shop.EnsureFresh()
	RefreshGrid()
	shop.stock_changed.connect(RefreshGrid)
	main.GetInstance()._resources.resources_changed.connect(RefreshGrid)

	var timer: Timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_countdown_tick)
	add_child(timer)
	_on_countdown_tick()

func RefreshGrid() -> void:
	for child in _grid_container.get_children():
		child.queue_free()
	_favor_slot = null

	var shop: ShopHandler = main.GetInstance()._shop
	var now: int = int(Time.get_unix_time_from_system())
	for i in shop._stock.size():
		var entry: Dictionary = shop._stock[i]
		var slot: ShopSlot = SHOP_SLOT_SCENE.instantiate()
		_grid_container.add_child(slot)
		slot._ID = i
		slot.Setup(entry)

		if(entry["category"] == Types.Category.FortunesFavor):
			_favor_slot = slot
			_RefreshFavorCooldownDisplay(shop, now)
		else:
			slot.SetSoldOut(entry["sold_out"])
		slot.ConnectButton(_on_slot_pressed)

func _RefreshFavorCooldownDisplay(p_shop: ShopHandler, p_now: int) -> void:
	if(ShopHandler.IsFavorAvailable(p_shop._favor_purchase_unix, p_now)):
		_favor_slot.ClearSoldOut()
		return
	var seconds_left: int = ShopHandler.GetSecondsUntilFavor(p_shop._favor_purchase_unix, p_now)
	_favor_slot.SetFavorCooldownDisplay(seconds_left)

func _on_countdown_tick() -> void:
	var shop: ShopHandler = main.GetInstance()._shop
	shop.EnsureFresh()

	var now: int = int(Time.get_unix_time_from_system())
	var seconds_left: int = ShopHandler.GetSecondsUntilRestock(shop._restock_anchor_unix, now)
	@warning_ignore("integer_division")
	var minutes: int = (seconds_left + 59) / 60
	_label_restock.text = "Restocks in " + str(minutes) + " minutes"

	if(_favor_slot != null and is_instance_valid(_favor_slot)):
		_RefreshFavorCooldownDisplay(shop, now)

func _on_slot_pressed(p_slot_index: int) -> void:
	var shop: ShopHandler = main.GetInstance()._shop
	var entry: Dictionary = shop._stock[p_slot_index]
	if(entry["sold_out"]):
		return
	if(main.GetInstance()._resources._silver < entry["price"]):
		_insufficient_option.show()
		return

	_pending_slot_index = p_slot_index
	_confirm_option.SetText("Confirm Purchase", "Buy this for " + str(entry["price"]) + " Silver?")
	_confirm_option.show()

func _on_confirm_buy() -> void:
	_confirm_option.hide()
	if(not main.GetInstance()._shop.Purchase(_pending_slot_index)):
		_insufficient_option.show()
		return

	_result_option.SetText("Purchase Complete", "The item has been added to your inventory.")
	_result_option.show()
	RefreshGrid()

func _on_back_button_up() -> void:
	_self_context._scene = _self_context._previous_scene
	main.GetInstance().change_scene(_self_context)
