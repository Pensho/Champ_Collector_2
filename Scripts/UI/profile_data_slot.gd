class_name ProfileDataSlot extends Control

@export var _button: Button
@export var _name_input: LineEdit
@export var _saved_at_label: Label
@export var _selection_outline: Panel

func ConnectButton(p_callable: Callable) -> void:
	_button.connect("button_up", p_callable)

func SetProfile(p_slot_number: int, p_meta: Dictionary) -> void:
	_name_input.placeholder_text = "Save slot " + str(p_slot_number + 1)
	_name_input.text = p_meta.get("profile_name", "")
	if (p_meta.has("saved_at")):
		_saved_at_label.text = "Last saved: " + str(p_meta["saved_at"])
	else:
		_saved_at_label.text = "Empty"

func GetEnteredName() -> String:
	return _name_input.text

func SetSelected(p_selected: bool) -> void:
	_selection_outline.visible = p_selected
