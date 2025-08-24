extends Node

var current_scene = null
var character_collection: Collection

const CONTEXT_TEST = preload("res://Data/Context_Test.tres")

const KNIGHT = preload("res://Data/Character_Player_Variants/Knight.tres")
const JESTER = preload("res://Data/Character_Player_Variants/Jester.tres")

func _ready() -> void:
	current_scene = get_tree().root.get_child(-1)
	print("current scene is: ", current_scene)
	character_collection = Collection.new()
	add_child(character_collection)

	character_collection.Add(JESTER.duplicate(true))
	character_collection.Add(KNIGHT.duplicate(true))
	character_collection.Add(JESTER.duplicate(true))
	
	var all_chars = character_collection.GetAllCharacters()
	for key in all_chars.keys():
		print("Found character in collection, ID: ", all_chars[key]._instanceID)
	
	var context: ContextContainer = load("res://Scenes/Context_Scenes/Context_Battle_Scene.tscn").instantiate()
	context._context = CONTEXT_TEST
	context._current_collection = character_collection
	
	change_scene("res://Scenes/ui/MainMenu.tscn", context)

func change_scene(target: String, context: ContextContainer) -> void:
	_deferred_change_scene(target, context)

func _deferred_change_scene(target: String, context: ContextContainer) -> void:
	## self.visible = true
	## Play transition animation
	if(current_scene.name != "Main"):
		self.remove_child(current_scene)
		current_scene.call_deferred("free")

	var scene = ResourceLoader.load(target)
	current_scene = scene.instantiate()
	add_child(current_scene)
	print("current scene is: ", current_scene)
	print(get_tree_string_pretty())
	current_scene.Init(context)
	## Play transition animation backwards
	## self.visible = false
