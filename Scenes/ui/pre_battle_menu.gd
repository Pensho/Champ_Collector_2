extends Control

const NR_OF_CHARACTERS_IN_BATTLE: int = 3

const BATTLE_TROLL = preload("res://Data/Battle_Variants/Battle_Troll.tres")
#const BATTLE_MILITIA = preload("res://Data/Battle_Variants/Battle_Militia.tres")

var _chosen_characters: Dictionary[int, Character]
var _character_collection: Array[Character]

func Init(p_context_container: ContextContainer) -> void:
	_character_collection = main._character_collection.GetAllCharacters().values()
	var collected_types = main._character_collection.GetCollectedTypes()

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "res://Scenes/ui/MainMenu.tscn"
	main.change_scene(context_container)

func _on_start_button_up() -> void:
	if (_chosen_characters.size() <= 0):
		print("Trying to start a battle without any selected characters.")
		return
	
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = BATTLE_TROLL
	context_container._scene = "res://Scenes/battle.tscn"
	context_container._player_battle_characters = _chosen_characters.values()
	
	main.change_scene(context_container)
	hide()

func _on_remove_char_button_up(p_char_slot: int) -> void:
	if (_chosen_characters.has(p_char_slot)):
		_chosen_characters.erase(p_char_slot)
	else:
		print("trying to remove a character from an empty slot nr: ", p_char_slot)

func _on_add_char_button_up(p_char_slot: int) -> void:
	if (_chosen_characters.size() >= NR_OF_CHARACTERS_IN_BATTLE):
		print("Trying to add a character when the roster is full.")
		return
	if (_character_collection.size() <= p_char_slot):
		print("Trying to add a character from an empty slot.")
		return
	for i in _chosen_characters:
		if (_chosen_characters[i]._instanceID == _character_collection[p_char_slot]._instanceID):
			print("Trying to add a character already in the chosen roster.")
			return
	for i in NR_OF_CHARACTERS_IN_BATTLE:
		if (!_chosen_characters.has(i)):
			_chosen_characters[i] = _character_collection[p_char_slot]
			return
