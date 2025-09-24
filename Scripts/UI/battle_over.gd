extends Control

@onready var _h_box_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer


func _ready() -> void:
	focus_button()

func focus_button() -> void:
	if _h_box_container:
		var button: Button = _h_box_container.get_child(0)
		button.grab_focus()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()
