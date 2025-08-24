extends Control

var _context: ContextContainer

signal start_game()
@onready var buttons_v_box: VBoxContainer = %ButtonsVBox

const BATTLE_TROLL = preload("res://Data/Battle_Variants/Battle_Troll.tres")

func _ready() -> void:
	focus_button()

func Init(context: ContextContainer) -> void:
	_context = context
	_context._context = BATTLE_TROLL

func _on_start_game_button_pressed() -> void:
	start_game.emit()
	main.change_scene("res://Scenes/battle.tscn", _context)
	hide()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()
		
func focus_button() -> void:
	if buttons_v_box:
		var button: Button = buttons_v_box.get_child(0)
		if button is Button:
			button.grab_focus()
