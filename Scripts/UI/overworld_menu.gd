extends Control

@export var _reclaimed_city_act: ActData
@export var _clockwork_spire_act: ActData
@export var _pirate_coves_act: ActData
@export var _iron_ledger_act: ActData

@warning_ignore("unused_parameter") # The overworld requires nothing from the ContextContainer.
func Init(_p_context_container: ContextContainer) -> void:
	pass

func EnterAct(p_act: ActData) -> void:
	var main_instance: Main_Instance = main.GetInstance()
	main_instance._progress.SetCurrentAct(p_act)
	main_instance._save_manager.RequestAutosave()
	main_instance.EnterHub()

func _on_reclaimed_city_pressed() -> void:
	EnterAct(_reclaimed_city_act)

func _on_clockwork_spire_pressed() -> void:
	EnterAct(_clockwork_spire_act)

func _on_pirate_coves_pressed() -> void:
	EnterAct(_pirate_coves_act)

func _on_iron_ledger_pressed() -> void:
	EnterAct(_iron_ledger_act)
