class_name ConfirmDeleteDialog extends Control

@export var _message_label: Label
@export var _background: ColorRect

var _confirm_func: Callable

func Init(p_profile_name: String) -> void:
	_message_label.text = "Delete \"" + p_profile_name + "\"? This cannot be undone."

func GetSize() -> Vector2:
	return Vector2(_background.get_rect().size.x, _background.get_rect().size.y)

func ConnectConfirm(p_callable: Callable) -> void:
	_confirm_func = p_callable

func _on_confirm_button_up() -> void:
	_confirm_func.call()
	self.hide()

func _on_cancel_button_up() -> void:
	self.hide()
