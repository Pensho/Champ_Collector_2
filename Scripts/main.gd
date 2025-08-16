extends Node

var current_scene = null
var character_collection: Collection

const KNIGHT = preload("res://Data/Character_Player_Variants/Knight.tres")

func _ready() -> void:
	# var root = get_tree().root
	# current_scene = root.get_child(-1)
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
	#if null != current_scene:
	#	current_scene.free()
	#var s = ResourceLoader.load(target)
	#current_scene = s.instantiate()
	#get_tree().root.add_child(current_scene)
	#get_tree().current_scene = current_scene
	get_tree().change_scene_to_file(target)

#func change_scene(target: String) -> void:
	## self.visible = true
	## Play transition animation
	#get_tree().change_scene_to_file(target)
	## Play transition animation backwards
	## self.visible = false
