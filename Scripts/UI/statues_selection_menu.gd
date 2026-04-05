extends Control


@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	pass

func _on_back_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://df6f1b4xoipjq"
	main.GetInstance().change_scene(context_container)

func _on_weapon_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = load("uid://dd77irpwqu5o8")
	context_container._previous_scene = "uid://d3kgucyfmcvip"
	context_container._scene = "uid://d3hg8jxy8xj8n"
	context_container._arguments["Boss_Scale"] = 1.4
	main.GetInstance().change_scene(context_container)

func _on_shield_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = load("uid://comvft2e4h5kt")
	context_container._previous_scene = "uid://d3kgucyfmcvip"
	context_container._scene = "uid://d3hg8jxy8xj8n"
	context_container._arguments["Boss_Scale"] = 1.4
	main.GetInstance().change_scene(context_container)
