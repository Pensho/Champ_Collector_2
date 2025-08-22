extends Node

var current_scene = null
var character_collection: Collection

const KNIGHT = preload("res://Data/Character_Player_Variants/Knight.tres")

func _ready() -> void:
	current_scene = get_tree().root.get_child(-1)
	print("current scene is: ", current_scene)
	character_collection = Collection.new()
	add_child(character_collection)

	character_collection.Add(KNIGHT.duplicate(true))
	character_collection.Add(KNIGHT.duplicate(true))
	
	var all_chars = character_collection.GetAllCharacters()
	for key in all_chars.keys():
		print("Found character in collection, ID: ", all_chars[key]._instanceID)
	
	change_scene("res://Scenes/ui/MainMenu.tscn")

func change_scene(target: String) -> void:
	_deferred_change_scene(target)

func _deferred_change_scene(target: String) -> void:
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
	## Play transition animation backwards
	## self.visible = false
