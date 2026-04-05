extends Control

@onready var _h_box_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer
@onready var _heading: Label = $MarginContainer/VBoxContainer/Label
@onready var _texture_rect_background: TextureRect = $TextureRect_Background

@export var _character_result_UI: Array[CharacterDamageResultUI]

var _context: ContextContainer = ContextContainer.new()

func _ready() -> void:
	focus_button()

func Init(p_context_container: ContextContainer) -> void:
	_context = p_context_container
	if(not p_context_container._arguments.has("Battle_Result")):
		print("There was no definition of win or loss after battle.")
		get_tree().quit()
	
	# Win or loss handling
	if(p_context_container._arguments["Battle_Result"] == "Loss"):
		_texture_rect_background.texture = load("res://Assets/Champ_Collector/UI/Loss_Screen/Loss_1.png")
		_texture_rect_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_texture_rect_background.size.x = 1280
		_texture_rect_background.size.y = 720
		_heading.text = "Lost"
	elif(p_context_container._arguments["Battle_Result"] == "Victory"):
		main.GetInstance()._progress.MarkDifficultyCompleted(
				_context._static_context.resource_path, _context._arguments["Difficulty"])
		var battle_context: Context_Battle = p_context_container._static_context as Context_Battle
		main.GetInstance()._resources._fortunes_favor += battle_context._loot_table._drop_result._fortunes_favor
		main.GetInstance()._resources._silver += battle_context._loot_table._drop_result._silver
		main.GetInstance()._resources._supplies += battle_context._loot_table._drop_result._supplies
	
	var total_damage_dealt = 0
	for character_ID in _context._player_battle_characters.size():
		total_damage_dealt += _context._arguments["character_dmg_" + str(character_ID)]
	
	for character_ID in _context._player_battle_characters.size():
		_character_result_UI[character_ID].SetName(_context._player_battle_characters[character_ID]._name)
		_character_result_UI[character_ID].SetTexture(
				main.GetInstance()._character_collection.GetCharacterTexture(
					_context._player_battle_characters[character_ID]._name))
		_character_result_UI[character_ID].SetDamageDealt(
				_context._arguments["character_dmg_" + str(character_ID)], total_damage_dealt)
		_character_result_UI[character_ID].show()

func focus_button() -> void:
	if _h_box_container:
		var button: Button = _h_box_container.get_child(0)
		button.grab_focus()

func _on_visibility_changed() -> void:
	if visible:
		focus_button()

func _on_button_end_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = _context._previous_scene
	main.GetInstance().change_scene(context_container)

func _on_button_replay_button_up() -> void:
	_context._scene = "uid://cc883blynrgq2"
	main.GetInstance().change_scene(_context)

func _on_button_edit_team_button_up() -> void:
	_context._scene = "uid://d3hg8jxy8xj8n"
	main.GetInstance().change_scene(_context)
