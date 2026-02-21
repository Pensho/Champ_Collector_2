extends Control

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	pass

func _on_war_room_button_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://df6f1b4xoipjq"
	main.GetInstance().change_scene(context_container)

#var context_container: ContextContainer = ContextContainer.new()
#context_container._scene = "res://Scenes/ui/Pre_Battle_Menu.tscn"
#main.GetInstance().change_scene(context_container)

func _on_button_view_collection_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "res://Scenes/ui/Inspect_Collection_Menu.tscn"
	main.GetInstance().change_scene(context_container)

func _on_button_quit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://c6c1o3oabj0pf"
	main.GetInstance().change_scene(context_container)
