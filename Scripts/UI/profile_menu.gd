extends Control

@export var _profiles: Array[ProfileDataSlot]
@export var _details_panel: ProfileDetailsPanel
@export var _button_save: Button
@export var _button_load: Button
@export var _button_delete: Button

var _confirm_delete_dialog: ConfirmDeleteDialog
var _selected_slot: int = -1

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(_p_context_container: ContextContainer) -> void:
	for i in _profiles.size():
		_profiles[i].ConnectButton(_on_profile_button.bind(i))
		UpdateProfileDataSlot(i)

	_confirm_delete_dialog = $ConfirmDeleteDialog
	_confirm_delete_dialog.position = Vector2i(
		(get_viewport_rect().size * 0.5) - (_confirm_delete_dialog.GetSize() * 0.5))
	_confirm_delete_dialog.hide()

	_details_panel.Clear()
	_UpdateActionButtons()

func UpdateProfileDataSlot(p_slot: int) -> void:
	_profiles[p_slot].SetProfile(p_slot, main.GetInstance()._save_manager.GetSlotMetadata(p_slot))

func _on_back_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://c6c1o3oabj0pf"
	main.GetInstance().change_scene(context_container)

func _on_profile_button(p_slot: int) -> void:
	_selected_slot = p_slot
	for i in _profiles.size():
		_profiles[i].SetSelected(i == p_slot)
	_details_panel.SetProfile(main.GetInstance()._save_manager.GetSlotMetadata(p_slot))
	_UpdateActionButtons()

func _UpdateActionButtons() -> void:
	if (_selected_slot == -1):
		_button_save.disabled = true
		_button_load.disabled = true
		_button_delete.disabled = true
		return

	var has_save: bool = main.GetInstance()._save_manager.HasSaveSlot(_selected_slot)
	_button_save.disabled = false
	_button_load.disabled = not has_save
	_button_delete.disabled = not has_save

func _on_save_button_up() -> void:
	var entered_name: String = _profiles[_selected_slot].GetEnteredName()
	if (not entered_name.is_empty()):
		main.GetInstance()._save_manager._active_profile_name = entered_name

	var succeeded: bool = main.GetInstance()._save_manager.Save(_selected_slot)
	if (succeeded):
		Notification_Handler.Notify("Game saved")
	else:
		Notification_Handler.Notify("Could not save the game", Types.Notification_Kind.Failure)

	UpdateProfileDataSlot(_selected_slot)
	_details_panel.SetProfile(main.GetInstance()._save_manager.GetSlotMetadata(_selected_slot))
	_UpdateActionButtons()

func _on_load_button_up() -> void:
	var succeeded: bool = main.GetInstance()._save_manager.Load(_selected_slot)
	if (succeeded):
		Notification_Handler.Notify("Game loaded")
	else:
		Notification_Handler.Notify("Could not load the game", Types.Notification_Kind.Failure)

func _on_delete_button_up() -> void:
	_confirm_delete_dialog.Init(_profiles[_selected_slot].GetEnteredName())
	_confirm_delete_dialog.ConnectConfirm(_on_delete_confirmed.bind(_selected_slot))
	_confirm_delete_dialog.show()

func _on_delete_confirmed(p_slot: int) -> void:
	var succeeded: bool = main.GetInstance()._save_manager.DeleteSave(p_slot)
	if (succeeded):
		Notification_Handler.Notify("Profile deleted")
	else:
		Notification_Handler.Notify("Could not delete the profile", Types.Notification_Kind.Failure)

	UpdateProfileDataSlot(p_slot)
	if (p_slot == _selected_slot):
		_details_panel.Clear()
		_profiles[p_slot].SetSelected(false)
		_selected_slot = -1
		_UpdateActionButtons()
