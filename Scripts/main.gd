extends Node

# var current_scene = null
#@export var current_scene: String = ""
var current_scene = null

func _ready() -> void:
	# var root = get_tree().root
	# current_scene = root.get_child(-1)
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
