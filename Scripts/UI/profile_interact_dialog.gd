class_name ProfileInteractDialog extends Control

var _name: String = ""

@export var _name_input: LineEdit
@export var _played_time_label: Label
@export var _saved_at_label: Label
@export var _background: ColorRect

const MAX_LENGTH_NAME: int = 16

var _save_func: Callable
var _load_func: Callable

func Init(p_meta_data: Dictionary) -> void:
	if (p_meta_data.has("profile_name")):
		_name = p_meta_data["profile_name"]
		_name_input.placeholder_text = _name
	if (p_meta_data.has("played_time")):
		print("p_meta_data.has(played_time): ", p_meta_data["played_time"])
		_played_time_label.text = "Played time: " + str(p_meta_data["played_time"])
	if (p_meta_data.has("saved_at")):
		_saved_at_label.text = "Last saved at: " + str(p_meta_data["saved_at"])

func GetSize() -> Vector2:
	return Vector2(_background.get_rect().size.x, _background.get_rect().size.y)

func ConnectSave(p_callable: Callable) -> void:
	_save_func = p_callable

func ConnectLoad(p_callable: Callable) -> void:
	_load_func = p_callable

func _on_cancel_button_up() -> void:
	print("Cancel")
	self.hide()

func _on_save_button_up() -> void:
	print("writing to _save_manager._active_profile_name with: ", _name_input.text)
	if(not _name_input.text.is_empty()):
		main.GetInstance()._save_manager._active_profile_name = _name_input.text
	_save_func.call()
	self.hide()

func _on_load_button_up() -> void:
	_load_func.call()
	self.hide()
