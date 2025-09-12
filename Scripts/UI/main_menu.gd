extends Control

var _player_battle_characters: Array[Character]

#signal start_game()
@onready var _buttons_v_box: VBoxContainer = %ButtonsVBox

const BATTLE_TROLL = preload("res://Data/Battle_Variants/Battle_Troll.tres")

func _ready() -> void:
	focus_button()

func Init(p_context_container: ContextContainer) -> void:
	if(p_context_container._current_collection.GetAllCharacters().size() >= 3):
		for i in 3:
			_player_battle_characters.append(p_context_container._current_collection.GetCharacter(i))
	else:
		for i in p_context_container._current_collection.GetAllCharacters():
			_player_battle_characters.append(p_context_container._current_collection.GetCharacter(i))

func _on_start_game_button_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = BATTLE_TROLL
	context_container._scene = "res://Scenes/battle.tscn"
	context_container._player_battle_characters = _player_battle_characters
	
	#start_game.emit()
	main.change_scene(context_container)
	hide()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()
		
func focus_button() -> void:
	if _buttons_v_box:
		var button: Button = _buttons_v_box.get_child(0)
		button.grab_focus()
