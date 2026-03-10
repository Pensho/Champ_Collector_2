extends Control

@export var _profiles: Array[ProfileDataSlot]

var dialog: ProfileInteractDialog

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	for i in _profiles.size():
		_profiles[i].ConnectButton(_on_profile_button.bind(i))
		UpdateProfileDataSlot(i)
	
	dialog = load("uid://dhudbbnbn7b3n").instantiate()
	add_child(dialog)
	dialog.position = (get_window().size / 2) - Vector2i(dialog.GetSize() * 0.5)
	dialog.hide()

func UpdateProfileDataSlot(p_slot: int) -> void:
	if(main.GetInstance()._save_manager.HasSaveSlot(p_slot)):
		if(main.GetInstance()._save_manager.GetSlotMetadata(p_slot).has("profile_name")):
			_profiles[p_slot].SetText(main.GetInstance()._save_manager.GetSlotMetadata(p_slot)["profile_name"])
	else:
		_profiles[p_slot].SetText("Save slot " + str(p_slot + 1) + " (Empty)")

func _on_back_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://c6c1o3oabj0pf"
	main.GetInstance().change_scene(context_container)

func _on_profile_button(p_slot: int) -> void:
	dialog.Init(main.GetInstance()._save_manager.GetSlotMetadata(p_slot))
	dialog.ConnectSave(main.GetInstance()._save_manager.Save.bind(p_slot))
	dialog.ConnectLoad(main.GetInstance()._save_manager.Load.bind(p_slot))
	dialog.show()
