extends Control

@onready var available_characters: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/Available_Characters

const NR_OF_CHARACTERS_IN_BATTLE: int = 3
const CHARACTER_CHOSEN_COLOR: Color = Color(0.1, 0.1, 0.1)
const CHARACTER_AVAILABLE_COLOR: Color = Color(1,1,1)

@export var _difficulty_option: OptionButton
@export var _chosen_character_slots: Array[MenuItemSlot]

var _chosen_characters: Dictionary[int, Character]
var _character_collection: Array[Character]
var _available_to_chosen_IDs: Dictionary[int, int] = {0: -1, 1: -1, 2: -1}
var _available_character_slots: Array[MenuItemSlot]
var _character_collection_size: int

var _self_context: ContextContainer

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
	
	for i in _available_character_slots.size():
		_available_character_slots[i]._ID = i
		_available_character_slots[i].ConnectButton(_on_add_char_button_up)
		if(i < _character_collection_size):
			_available_character_slots[i].SetHeldObjectTexture(main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[i]._role))
			_available_character_slots[i].level.text = str(_character_collection[i]._level)
	
	for i in range(1, main.GetInstance()._progress.GetCurrentEncounterDifficulty(_self_context._static_context.resource_path) + 1):
		_difficulty_option.add_item("Difficulty " + str(i), i)
	_difficulty_option.select(0)

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = _self_context._previous_scene
	main.GetInstance().change_scene(context_container)

func _on_start_button_up() -> void:
	if (_chosen_characters.size() <= 0):
		print("Trying to start a battle without any selected characters.")
		return
	
	_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()
	_self_context._scene = "res://Scenes/battle.tscn"
	_self_context._player_battle_characters = _chosen_characters.values()
	
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
		print("_available_to_chosen_IDs[p_char_slot]: ", _available_to_chosen_IDs[p_char_slot])
		_available_character_slots[_available_to_chosen_IDs[p_char_slot]].SetHeldObjectModulate(CHARACTER_AVAILABLE_COLOR)
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
		if (_chosen_characters[i]._instanceID == _character_collection[p_char_slot]._instanceID):
			print("Trying to add a character already in the chosen roster.")
			return
		if (_chosen_characters[i]._name == _character_collection[p_char_slot]._name):
			print("Trying to add two of the same type of character.")
			return
	for i in NR_OF_CHARACTERS_IN_BATTLE:
		if (!_chosen_characters.has(i)):
			_chosen_characters[i] = _character_collection[p_char_slot]
			_chosen_character_slots[i].SetHeldObjectTexture(_available_character_slots[p_char_slot].texture_rect.texture)
			print("Time to darken _available_character_slots for slot nr: ", p_char_slot, " to color: ", CHARACTER_CHOSEN_COLOR)
			_available_character_slots[p_char_slot].SetHeldObjectModulate(CHARACTER_CHOSEN_COLOR)
			_available_to_chosen_IDs[i] = p_char_slot
			return
