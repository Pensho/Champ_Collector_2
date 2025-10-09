extends Control

@onready var _buttons_v_box: VBoxContainer = %ButtonsVBox

func _ready() -> void:
	focus_button()

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	pass

func _on_start_game_button_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "res://Scenes/ui/Pre_Battle_Menu.tscn"
	main.change_scene(context_container)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()

func focus_button() -> void:
	if _buttons_v_box:
		var button: Button = _buttons_v_box.get_child(0)
		button.grab_focus()
