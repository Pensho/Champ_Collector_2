extends Control


@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	pass


func _on_back_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://df6f1b4xoipjq"
	main.GetInstance().change_scene(context_container)
