extends Control

@onready var _h_box_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer
@onready var _heading: Label = $MarginContainer/VBoxContainer/Label
@onready var _texture_rect_background: TextureRect = $TextureRect_Background

var _previous_context: ContextContainer
var _player_battle_characters: Array[Character]

func _ready() -> void:
	focus_button()

func Init(p_context_container: ContextContainer) -> void:
	_previous_context = p_context_container
	if(not p_context_container._arguments.has("Battle_Result")):
		print("There was no definition of win or loss after battle.")
		OS.crash("There was no definition of win or loss after battle.")
		
	if(p_context_container._arguments["Battle_Result"] == "Loss"):
		_texture_rect_background.texture = load("res://Assets/Champ_Collector/UI/Loss_Screen/Loss_1.png")
		_texture_rect_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_texture_rect_background.size.x = 1280
		_texture_rect_background.size.y = 720
		_heading.text = "Lost"
	elif(p_context_container._arguments["Battle_Result"] == "Victory"):
		pass

	if(main.GetInstance()._character_collection.Size() >= 3):
		for i in 3:
			_player_battle_characters.append(main.GetInstance()._character_collection.GetCharacter(i))
	else:
		var characters = main.GetInstance()._character_collection.GetAllCharacters()
		for i in characters:
			_player_battle_characters.append(i)

func focus_button() -> void:
	if _h_box_container:
		var button: Button = _h_box_container.get_child(0)
		button.grab_focus()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()

func _on_button_end_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = _previous_context._previous_scene
	main.GetInstance().change_scene(context_container)

func _on_button_replay_button_up() -> void:
	_previous_context = ContextContainer.new()
	_previous_context._scene = "res://Scenes/battle.tscn"
	main.GetInstance().change_scene(_previous_context)

func _on_button_edit_team_button_up() -> void:
	_previous_context = ContextContainer.new()
	_previous_context._scene = "res://Scenes/ui/Pre_Battle_Menu.tscn"
	main.GetInstance().change_scene(_previous_context)
