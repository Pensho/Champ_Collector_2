extends Control

@onready var _h_box_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer
@onready var _heading: Label = $MarginContainer/VBoxContainer/Label
@onready var _texture_rect_background: TextureRect = $TextureRect_Background

const BATTLE_MILITIA = preload("res://Data/Battle_Variants/Battle_Militia.tres")

var _player_battle_characters: Array[Character]

func _ready() -> void:
	focus_button()

func Init(p_context_container: ContextContainer) -> void:
	if(p_context_container._util_text == "Loss"):
		_texture_rect_background.texture = load("res://Assets/Champ Collector/UI/Loss_Screen/Loss_1.png")
		_texture_rect_background.size.x = 1280
		_texture_rect_background.size.y = 720
		_heading.text = "Lost"
	elif(p_context_container._util_text == "Victory"):
		pass

	if(main._character_collection.GetAllCharacters().size() >= 3):
		for i in 3:
			_player_battle_characters.append(main._character_collection.GetCharacter(i))
	else:
		for i in main._character_collection.GetAllCharacters():
			_player_battle_characters.append(main._character_collection.GetCharacter(i))

func focus_button() -> void:
	if _h_box_container:
		var button: Button = _h_box_container.get_child(0)
		button.grab_focus()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()

func _on_button_end_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "res://Scenes/ui/MainMenu.tscn"
	main.change_scene(context_container)

func _on_button_replay_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = BATTLE_MILITIA
	context_container._scene = "res://Scenes/battle.tscn"
	context_container._player_battle_characters = _player_battle_characters

	main.change_scene(context_container)
	hide()

func _on_button_edit_team_button_up() -> void:
	print("Not implemented yet.")
