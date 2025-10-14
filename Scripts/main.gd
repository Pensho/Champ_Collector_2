extends Node

var _current_scene = null
var _character_collection: CharacterCollection
var _item_collection: ItemCollection

const GAME_BALANCE = preload("res://Data/Game_Balance.tres")

const KNIGHT = preload("res://Data/Character_Player_Variants/Knight.tres")
const JESTER = preload("res://Data/Character_Player_Variants/Jester.tres")
const BAR_BRAWLER = preload("res://Data/Character_Player_Variants/Bar_Brawler.tres")
const HERALD_OF_THE_LOOM = preload("res://Data/Character_Player_Variants/Herald_of_the_loom.tres")
const THIEF = preload("res://Data/Character_Player_Variants/Thief.tres")

func _ready() -> void:
	_current_scene = get_tree().root.get_child(-1)
	print("current scene is: ", _current_scene)
	_character_collection = CharacterCollection.new()
	add_child(_character_collection)
	var context_container: ContextContainer = ContextContainer.new()

	_character_collection.Add(KNIGHT.duplicate(true))
	_character_collection.Add(THIEF.duplicate(true))
	_character_collection.Add(BAR_BRAWLER.duplicate(true))
	_character_collection.Add(JESTER.duplicate(true))
	_character_collection.Add(HERALD_OF_THE_LOOM.duplicate(true))

	var all_chars = _character_collection.GetAllCharacters()
	for key in all_chars.keys():
		print("Found character in collection, ID: ", all_chars[key]._instanceID, " name: ", all_chars[key]._name)

	context_container._scene = "res://Scenes/ui/MainMenu.tscn"
	change_scene(context_container)

func change_scene(p_context: ContextContainer) -> void:
	_deferred_change_scene(p_context)

func _deferred_change_scene(p_context: ContextContainer) -> void:
	## self.visible = true
	## Play transition animation
	if(_current_scene.name != "Main"):
		self.remove_child(_current_scene)
		_current_scene.call_deferred("free")

	var scene = ResourceLoader.load(p_context._scene)
	_current_scene = scene.instantiate()
	add_child(_current_scene)
	print("current scene is: ", _current_scene)
	#print(get_tree_string_pretty())
	_current_scene.Init(p_context)
	## Play transition animation backwards
	## self.visible = false
