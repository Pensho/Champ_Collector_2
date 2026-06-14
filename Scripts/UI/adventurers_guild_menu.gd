extends Control

var _hollow_ledger_window: HollowLedgerWindow

@warning_ignore("unused_parameter") # Adventurers Guild menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	_hollow_ledger_window = load("res://Scenes/ui/Hollow_Ledger_Window.tscn").instantiate()
	add_child(_hollow_ledger_window)
	_hollow_ledger_window.position = Vector2i((get_window().size * 0.5) - (_hollow_ledger_window.GetSize() * 0.5))
	_hollow_ledger_window.Init()
	_hollow_ledger_window.hide()

func _on_town_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)

func _on_fortunes_favor_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://dqx1m7r3y4t2k"
	main.GetInstance().change_scene(context_container)

func _on_drop_rates_button_up() -> void:
	_hollow_ledger_window.show()
