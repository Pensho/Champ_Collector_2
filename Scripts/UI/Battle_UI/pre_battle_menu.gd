extends Control

const MENU_ITEM_SLOT = preload("uid://di0y70sbai3yw")

const NR_OF_CHARACTERS_IN_BATTLE: int = 3
const CHARACTER_CHOSEN_COLOR: Color = Color(0.1, 0.1, 0.1)
const CHARACTER_AVAILABLE_COLOR: Color = Color(1,1,1)
const NR_OF_REAGENTS_IN_BATTLE: int = 3

@export var _difficulty_option: OptionButton
@export var _chosen_character_slots: Array[MenuItemSlot]
@export var _chosen_reagent_slots: Array[MenuItemSlot]
@export var _grid_container_reagents: GridContainer

var _chosen_characters: Dictionary[int, Character]
var _character_collection: Array[Character]
var _available_to_chosen_ids: Dictionary[int, int] = {0: -1, 1: -1, 2: -1}
var _available_character_slots: Array[MenuItemSlot]
var _character_collection_size: int

# Reagent selection: chosen slot index -> reagent registry key.
var _chosen_reagents: Dictionary[int, String]
var _available_reagent_slots: Array[MenuItemSlot]
var _displayed_reagent_keys: Array[String]
var _reagent_collection: ReagentCollection

var _self_context: ContextContainer

@onready var available_characters: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/Available_Characters

func Init(p_context_container: ContextContainer) -> void:
	if(null == p_context_container._static_context):
		print("There is no static context to infer what battle has been chosen.")
		return
	_self_context = p_context_container
	
	_available_character_slots.append_array(GetMenuItemSlotChildren(available_characters))
	_character_collection_size = main.GetInstance()._character_collection.Size()
	_character_collection = main.GetInstance()._character_collection.GetAllCharacters().values()
	
	for i in _chosen_character_slots.size():
		_chosen_character_slots[i]._ID = i
		_chosen_character_slots[i].ConnectButton(_on_remove_char_button_up)

	_reagent_collection = main.GetInstance()._reagent_collection
	for i in _chosen_reagent_slots.size():
		_chosen_reagent_slots[i]._ID = i
		_chosen_reagent_slots[i].ConnectButton(_on_remove_reagent_button_up)
	RefreshAvailableReagents()
	
	for i in _available_character_slots.size():
		_available_character_slots[i]._ID = i
		_available_character_slots[i].ConnectButton(_on_add_char_button_up)
		if(i < _character_collection_size):
			_available_character_slots[i].SetHeldObjectTexture(
					main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[i]._name))
			_available_character_slots[i].level.text = str(_character_collection[i]._level)
	
	var encounter_id: String = _self_context._static_context.resource_path
	if _self_context._adventure_state != null:
		_difficulty_option.visible = false
	elif encounter_id.is_empty():
		_difficulty_option.add_item("Difficulty " + str(_self_context._arguments.get("Difficulty", 1)), 1)
		_difficulty_option.select(_difficulty_option.item_count - 1)
		_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()
	else:
		for i in range(1, main.GetInstance()._progress.GetCurrentEncounterDifficulty(encounter_id) + 1):
			_difficulty_option.add_item("Difficulty " + str(i), i)
		_difficulty_option.select(_difficulty_option.item_count - 1)
		_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()

func _on_exit_button_up() -> void:
	_self_context._scene = _self_context._previous_scene
	main.GetInstance().change_scene(_self_context)

func _on_start_button_up() -> void:
	if (_chosen_characters.size() <= 0):
		print("Trying to start a battle without any selected characters.")
		return

	var total: int = int(_self_context._arguments.get("Supply_Cost", GameBalance.ENCOUNTER_BASE_SUPPLY_COST))
	if not main.GetInstance()._resources.SpendSupplies(total):
		print("Not enough supplies to start this encounter.")
		return
	_self_context._arguments["Supply_Cost_Paid"] = total

	if _self_context._adventure_state == null:
		_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()
	_self_context._scene = "uid://cc883blynrgq2"
	_self_context._player_battle_characters = _chosen_characters.values()
	_self_context._battle_reagents.assign(_chosen_reagents.values())

	main.GetInstance().change_scene(_self_context)
	hide()

func GetMenuItemSlotChildren(p_start_node: Node) -> Array[MenuItemSlot]:
	var result: Array[MenuItemSlot] = []
	for child in p_start_node.get_children():
		if child is MenuItemSlot:
			result.append(child)
		result += GetMenuItemSlotChildren(child)
	return result

func _on_remove_char_button_up(p_char_slot: int) -> void:
	if (_chosen_characters.has(p_char_slot)):
		_chosen_characters.erase(p_char_slot)
		_chosen_character_slots[p_char_slot].SetHeldObjectTexture(null)
		print("p_char_slot: ", p_char_slot)
		print("_available_to_chosen_ids[p_char_slot]: ", _available_to_chosen_ids[p_char_slot])
		_available_character_slots[_available_to_chosen_ids[p_char_slot]].SetHeldObjectModulate(
				CHARACTER_AVAILABLE_COLOR)
	else:
		print("trying to remove a character from an empty slot nr: ", p_char_slot)

func _on_add_char_button_up(p_char_slot: int) -> void:
	if (_chosen_characters.size() >= NR_OF_CHARACTERS_IN_BATTLE):
		print("Trying to add a character when the roster is full.")
		return
	if (_character_collection.size() <= p_char_slot):
		print("Trying to add a character from an empty slot.")
		return
	for i in _chosen_characters.keys():
		if (_chosen_characters[i]._instance_ID == _character_collection[p_char_slot]._instance_ID):
			print("Trying to add a character already in the chosen roster.")
			return
		if (_chosen_characters[i]._name == _character_collection[p_char_slot]._name):
			print("Trying to add two of the same type of character.")
			return
	for i in NR_OF_CHARACTERS_IN_BATTLE:
		if (!_chosen_characters.has(i)):
			_chosen_characters[i] = _character_collection[p_char_slot]
			_chosen_character_slots[i].SetHeldObjectTexture(
					_available_character_slots[p_char_slot].texture_rect.texture)
			_available_character_slots[p_char_slot].SetHeldObjectModulate(CHARACTER_CHOSEN_COLOR)
			_available_to_chosen_ids[i] = p_char_slot
			return

func RefreshAvailableReagents() -> void:
	for slot in _available_reagent_slots:
		slot.queue_free()
	_available_reagent_slots.clear()
	_displayed_reagent_keys.clear()

	var owned: Dictionary[String, int] = _reagent_collection.GetAllOwned()
	for reagent_key in owned.keys():
		var reagent_data: ReagentData = ReagentRegistry.Get(reagent_key)
		var slot: MenuItemSlot = MENU_ITEM_SLOT.instantiate()
		_grid_container_reagents.add_child(slot)
		slot._ID = _displayed_reagent_keys.size()
		slot.ConnectButton(_on_add_reagent_button_up)
		slot.SetHeldObjectTexture(reagent_data.icon)
		slot.SetTextureOutline(reagent_data.rarity)
		slot.level.text = str(owned[reagent_key])
		_available_reagent_slots.append(slot)
		_displayed_reagent_keys.append(reagent_key)

func RemainingAvailableCount(p_reagent_key: String) -> int:
	var chosen_count: int = 0
	for key in _chosen_reagents.values():
		if (key == p_reagent_key):
			chosen_count += 1
	return _reagent_collection.GetCount(p_reagent_key) - chosen_count

func _on_add_reagent_button_up(p_reagent_slot: int) -> void:
	if (_chosen_reagents.size() >= NR_OF_REAGENTS_IN_BATTLE):
		print("Trying to add a reagent when the loadout is full.")
		return
	if (_displayed_reagent_keys.size() <= p_reagent_slot):
		print("Trying to add a reagent from an empty slot.")
		return
	var reagent_key: String = _displayed_reagent_keys[p_reagent_slot]
	if (RemainingAvailableCount(reagent_key) <= 0):
		print("Trying to add more of a reagent than is owned.")
		return
	var reagent_data: ReagentData = ReagentRegistry.Get(reagent_key)
	for i in NR_OF_REAGENTS_IN_BATTLE:
		if (!_chosen_reagents.has(i)):
			_chosen_reagents[i] = reagent_key
			_chosen_reagent_slots[i].SetHeldObjectTexture(reagent_data.icon)
			_chosen_reagent_slots[i].SetTextureOutline(reagent_data.rarity)
			if (RemainingAvailableCount(reagent_key) <= 0):
				_available_reagent_slots[p_reagent_slot].SetHeldObjectModulate(CHARACTER_CHOSEN_COLOR)
			return

func _on_remove_reagent_button_up(p_reagent_slot: int) -> void:
	if (!_chosen_reagents.has(p_reagent_slot)):
		print("trying to remove a reagent from an empty slot nr: ", p_reagent_slot)
		return
	var reagent_key: String = _chosen_reagents[p_reagent_slot]
	_chosen_reagents.erase(p_reagent_slot)
	_chosen_reagent_slots[p_reagent_slot].SetHeldObjectTexture(null)
	for i in _displayed_reagent_keys.size():
		if (_displayed_reagent_keys[i] == reagent_key):
			_available_reagent_slots[i].SetHeldObjectModulate(CHARACTER_AVAILABLE_COLOR)
			break
