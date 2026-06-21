class_name Main_Instance extends Node

const LANCER = preload("res://Data/Character_Player_Variants/Lancer.tres")
const JESTER = preload("res://Data/Character_Player_Variants/Jester.tres")
const BAR_BRAWLER = preload("res://Data/Character_Player_Variants/Bar_Brawler.tres")
const HERALD_OF_THE_LOOM = preload("res://Data/Character_Player_Variants/Herald_of_the_loom.tres")
const THIEF = preload("res://Data/Character_Player_Variants/Thief.tres")
const CHRONOPHAGE = preload("uid://wofv42g341ac")
const BLOODMAGE = preload("uid://7adgp1emx6yk")
const TIDAL_CORSAIR = preload("uid://bmqvx8opoocu7")
const CENTAUR_LANCER = preload("uid://cgpw0pv0l4wn4")
const CENTAUR_ARCHIVIST = preload("uid://dkdgfkpt6si8y")
const TACTICIAN = preload("uid://dy22lp5h48s5f")

var _current_scene = null
var _character_collection: CharacterCollection
var _item_collection: ItemCollection
var _resources: ResourceHandler
var _progress: ProgressHandler
var _save_manager: SaveManager
var _adventure_state_handler: AdventureStateHandler

func Init() -> void:
	_current_scene = self
	_current_scene.name = "Main"
	print("current scene is: ", _current_scene)

	_character_collection = CharacterCollection.new()
	add_child(_character_collection)
	_item_collection = ItemCollection.new()
	add_child(_item_collection)
	_resources = ResourceHandler.new()
	add_child(_resources)
	_progress = ProgressHandler.new()
	add_child(_progress)
	_save_manager = SaveManager.new()
	add_child(_save_manager)
	_adventure_state_handler = AdventureStateHandler.new()
	_adventure_state_handler.name = "AdventureStateHandler"
	add_child(_adventure_state_handler)
	_adventure_state_handler.add_to_group(SaveManager.GROUP_SAVEABLE)

	var context_container: ContextContainer = ContextContainer.new()

	_character_collection.Add(LANCER.duplicate(true))
	_character_collection.Add(THIEF.duplicate(true))
	_character_collection.Add(BAR_BRAWLER.duplicate(true))
	_character_collection.Add(JESTER.duplicate(true))
	_character_collection.Add(CHRONOPHAGE.duplicate(true))
	_character_collection.Add(TIDAL_CORSAIR.duplicate(true))
	_character_collection.Add(CENTAUR_LANCER.duplicate(true))
	_character_collection.Add(CENTAUR_ARCHIVIST.duplicate(true))
	_character_collection.Add(TACTICIAN.duplicate(true))

	context_container._scene = "uid://c6c1o3oabj0pf"
	change_scene(context_container)

func change_scene(p_context: ContextContainer) -> void:
	_deferred_change_scene(p_context)

func _deferred_change_scene(p_context: ContextContainer) -> void:
	if(_current_scene.name != "Main" and _current_scene.name != "RunFromEditor"):
		self.remove_child(_current_scene)
		_current_scene.call_deferred("free")

	var scene := ResourceLoader.load(p_context._scene)
	_current_scene = scene.instantiate()
	add_child(_current_scene)
	print("current scene is: ", _current_scene)
	_current_scene.Init(p_context)
