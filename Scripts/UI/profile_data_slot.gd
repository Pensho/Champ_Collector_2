class_name ProfileDataSlot extends Control

@export var _button: Button
@export var _label: Label

func ConnectButton(p_callable: Callable) -> void:
	_button.connect("button_up", p_callable)

func SetText(p_text: String) -> void:
	_label.text = p_text
