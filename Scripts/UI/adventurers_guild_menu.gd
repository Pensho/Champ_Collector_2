extends Control

@warning_ignore("unused_parameter") # Adventurers Guild menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	pass

func _on_town_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)

func _on_fortunes_favor_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://dqx1m7r3y4t2k"
	main.GetInstance().change_scene(context_container)

func _on_drop_rates_button_up() -> void:
	pass # Fortune's Favor drop rate display is implemented in a future plan.
