extends Control

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	pass


func _on_town_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)


func _on_statues_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://d3kgucyfmcvip"
	main.GetInstance().change_scene(context_container)
