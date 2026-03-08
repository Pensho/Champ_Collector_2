extends Control

@export var _profile_1: ProfileDataSlot
@export var _profile_2: ProfileDataSlot
@export var _profile_3: ProfileDataSlot

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	var _my_data: Dictionary = {"a" : 1, "b" : 3}
	_profile_1.ConnectButton(main.GetInstance()._save_manager.Save.bind(0, _my_data))

func _on_back_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://c6c1o3oabj0pf"
	main.GetInstance().change_scene(context_container)
