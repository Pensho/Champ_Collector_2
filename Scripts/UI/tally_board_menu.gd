class_name TallyBoardMenu extends Control

const BUTTON_WITH_OPTIONS_SCENE: PackedScene = preload("uid://c7smqpmfvs0ih")
const TALLY_BOARD_SLOT_SCENE: PackedScene = preload("uid://dgq6dbtifjlib")

var _self_context: ContextContainer
var _confirm_option: ButtonWithOptions
var _insufficient_option: ButtonWithOptions
var _roster_full_option: ButtonWithOptions
var _result_option: ButtonWithOptions
var _pending_slot_index: int = -1

@onready var _label_restock: Label = $Label_Restock
@onready var _grid_container: GridContainer = $GridArea/GridContainer

func Init(p_context_container: ContextContainer) -> void:
	_self_context = p_context_container

	_confirm_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_confirm_option)
	_confirm_option.SetLeftButton("Buy", _on_confirm_buy)
	_confirm_option.position = Vector2i((get_viewport_rect().size * 0.5) - (_confirm_option.GetSize() * 0.5))
	_confirm_option.hide()

	_insufficient_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_insufficient_option)
	_insufficient_option.SetText("Not Enough Tallies", "You don't have enough Tallies for this champion.")
	_insufficient_option.position = (
			Vector2i((get_viewport_rect().size * 0.5) - (_insufficient_option.GetSize() * 0.5)))
	_insufficient_option.hide()

	_roster_full_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_roster_full_option)
	_roster_full_option.SetText("Roster Full", "Free up a roster slot before recruiting another champion.")
	_roster_full_option.position = (
			Vector2i((get_viewport_rect().size * 0.5) - (_roster_full_option.GetSize() * 0.5)))
	_roster_full_option.hide()

	_result_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_result_option)
	_result_option.position = Vector2i((get_viewport_rect().size * 0.5) - (_result_option.GetSize() * 0.5))
	_result_option.hide()

func _ready() -> void:
	var board: TallyBoardHandler = main.GetInstance()._tally_board
	board.EnsureFresh()
	RefreshGrid()
	board.stock_changed.connect(RefreshGrid)
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

	var board: TallyBoardHandler = main.GetInstance()._tally_board
	for i in board._offers.size():
		var entry: Dictionary = board._offers[i]
		var slot: TallyBoardSlot = TALLY_BOARD_SLOT_SCENE.instantiate()
		_grid_container.add_child(slot)
		slot._ID = i
		slot.Setup(entry)
		slot.SetSoldOut(entry["sold_out"])
		slot.ConnectButton(_on_slot_pressed)

func _on_countdown_tick() -> void:
	var board: TallyBoardHandler = main.GetInstance()._tally_board
	board.EnsureFresh()

	var now: int = int(Time.get_unix_time_from_system())
	var seconds_left: int = TallyBoardHandler.GetSecondsUntilRestock(board._restock_anchor_unix, now)
	_label_restock.text = "Restocks in " + ShopMenu.FormatRestockCountdown(seconds_left)

func _on_slot_pressed(p_slot_index: int) -> void:
	var board: TallyBoardHandler = main.GetInstance()._tally_board
	var entry: Dictionary = board._offers[p_slot_index]
	if(entry["sold_out"]):
		return
	if(main.GetInstance()._character_collection.IsTheCollectionFull()):
		_roster_full_option.show()
		return
	if(main.GetInstance()._resources.GetTallies() < entry["price"]):
		_insufficient_option.show()
		return

	_pending_slot_index = p_slot_index
	_confirm_option.SetText("Confirm Recruitment", "Recruit this champion for " + str(entry["price"]) + " Tallies?")
	_confirm_option.show()

func _on_confirm_buy() -> void:
	_confirm_option.hide()
	if(not main.GetInstance()._tally_board.Purchase(_pending_slot_index)):
		_insufficient_option.show()
		return

	_result_option.SetText("Recruitment Complete", "The champion has joined your roster.")
	_result_option.show()
	RefreshGrid()

func _on_back_button_up() -> void:
	_self_context._scene = _self_context._previous_scene
	main.GetInstance().change_scene(_self_context)
