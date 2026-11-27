extends Control

const NO_ADVENTURES_TOOLTIP: String = "No adventures lead out from here yet."

@export var _adventure_button: TextureButton

@warning_ignore("unused_parameter") # The Region Map reads its act from progress, not the ContextContainer.
func Init(_p_context_container: ContextContainer) -> void:
	var has_adventures: bool = main.GetInstance()._progress.GetCurrentAct().HasAdventures()
	_adventure_button.disabled = not has_adventures
	_adventure_button.tooltip_text = "" if has_adventures else NO_ADVENTURES_TOOLTIP

func _on_town_pressed() -> void:
	main.GetInstance().EnterHub()

func _on_caravan_pressed() -> void:
	Notification_Handler.Notify("Not available in demo.")

func _on_adventure_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cwjabuf3kdtft"
	context_container._previous_scene = scene_file_path
	context_container._arguments["Act"] = main.GetInstance()._progress.GetCurrentAct()
	main.GetInstance().change_scene(context_container)

func _on_experience_quests_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = load("uid://dstgijwmiqvo1") # Battle Variant, Battle_Context
	context_container._previous_scene = scene_file_path
	context_container._scene = "uid://d3hg8jxy8xj8n"
	main.GetInstance().change_scene(context_container)
