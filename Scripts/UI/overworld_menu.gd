extends Control

const RECLAIMED_CITY_HUB: String = "uid://cfdrcdtsx2jh7"
const CLOCKWORK_SPIRE_HUB: String = "res://Scenes/Hubs/Clockwork_Spire/Clockwork_Spire.tscn"
const PIRATE_COVES_HUB: String = "res://Scenes/Hubs/Pirate_Coves/Pirate_Coves.tscn"
const IRON_LEDGER_HUB: String = "res://Scenes/Hubs/Iron_Ledger/Iron_Ledger.tscn"

@warning_ignore("unused_parameter") # The overworld requires nothing from the ContextContainer.
func Init(_p_context_container: ContextContainer) -> void:
	pass

func GoToHub(p_hub_scene: String) -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = p_hub_scene
	main.GetInstance().change_scene(context_container)

func _on_reclaimed_city_pressed() -> void:
	GoToHub(RECLAIMED_CITY_HUB)

func _on_clockwork_spire_pressed() -> void:
	GoToHub(CLOCKWORK_SPIRE_HUB)

func _on_pirate_coves_pressed() -> void:
	GoToHub(PIRATE_COVES_HUB)

func _on_iron_ledger_pressed() -> void:
	GoToHub(IRON_LEDGER_HUB)
