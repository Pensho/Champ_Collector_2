extends Control

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(_p_context_container: ContextContainer) -> void:
	pass

func _on_adventure_guild_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "res://Scenes/Hubs/Adventurers_Guild/Adventurers_Guild.tscn"
	main.GetInstance().change_scene(context_container)

func _on_war_room_button_pressed() -> void:
	main.GetInstance().EnterRegionMap()

func _on_button_view_collection_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://b6ynhcan7pnn8"
	main.GetInstance().change_scene(context_container)

func _on_button_shop_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "res://Scenes/ui/Shop.tscn"
	context_container._previous_scene = scene_file_path
	context_container._arguments["Background_Texture"] = (
			"res://Assets/Champ_Collector/Hubs/Reclaimed_City/Reclaimed_1.jpg")
	main.GetInstance().change_scene(context_container)

func _on_button_quit_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://c6c1o3oabj0pf"
	main.GetInstance().change_scene(context_container)
