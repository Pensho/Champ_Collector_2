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
	context_container._static_context = load("uid://dd77irpwqu5o8") # Battle Variant, Battle_Context
	context_container._previous_scene = "res://Scenes/Hubs/Statue_Selection/Statue_Selection.tscn"
	context_container._scene = "res://Scenes/ui/Pre_Battle_Menu.tscn"
	context_container._arguments["Boss_Scale"] = 1.4
	main.GetInstance().change_scene(context_container)

func _on_shield_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = load("uid://comvft2e4h5kt") # Battle Variant, Battle_Context
	context_container._previous_scene = "res://Scenes/Hubs/Statue_Selection/Statue_Selection.tscn"
	context_container._scene = "res://Scenes/ui/Pre_Battle_Menu.tscn"
	context_container._arguments["Boss_Scale"] = 1.4
	main.GetInstance().change_scene(context_container)
