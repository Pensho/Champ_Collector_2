extends DebugPage

const MAX_PLAYER_CHARACTERS: int = 3

@export var _character_list: VBoxContainer
@export var _enemy_wave_option: OptionButton
@export var _difficulty_spin: SpinBox
@export var _status_label: Label

var _selected_instance_ids: Array[int] = []
var _checkboxes: Dictionary[int, CheckBox] = {}

func _ready() -> void:
	page_title = "Battle Launcher"
	for wave_name in DebugCatalog.BATTLE_CONTEXTS.keys():
		_enemy_wave_option.add_item(wave_name)
	_difficulty_spin.min_value = 1
	_difficulty_spin.max_value = Game_Balance.MAX_DIFFICULTY

func Refresh() -> void:
	_status_label.text = ""
	PopulateCharacterList()

func PopulateCharacterList() -> void:
	for child in _character_list.get_children():
		child.queue_free()
	_checkboxes.clear()
	_selected_instance_ids.clear()

	var collection: CharacterCollection = main.GetInstance()._character_collection
	for instance_id in collection.GetAllCharacters().keys():
		var character: Character = collection.GetCharacter(instance_id)
		var checkbox: CheckBox = CheckBox.new()
		checkbox.text = character._name + " (Level " + str(character._level) + ")"
		checkbox.toggled.connect(_on_character_toggled.bind(instance_id))
		_character_list.add_child(checkbox)
		_checkboxes[instance_id] = checkbox

func _on_character_toggled(p_pressed: bool, p_instance_id: int) -> void:
	if(p_pressed):
		if(_selected_instance_ids.size() >= MAX_PLAYER_CHARACTERS):
			_checkboxes[p_instance_id].set_pressed_no_signal(false)
			return
		_selected_instance_ids.append(p_instance_id)
	else:
		_selected_instance_ids.erase(p_instance_id)

func _on_launch_battle_button_up() -> void:
	if(_selected_instance_ids.is_empty()):
		_status_label.text = "Select at least one champion."
		return
	if(_enemy_wave_option.item_count == 0):
		_status_label.text = "No enemy wave available."
		return

	var collection: CharacterCollection = main.GetInstance()._character_collection
	var player_characters: Array[Character] = []
	for instance_id in _selected_instance_ids:
		player_characters.append(collection.GetCharacter(instance_id))

	var wave_name: String = _enemy_wave_option.get_item_text(_enemy_wave_option.selected)
	var battle_context: Context_Battle = DebugCatalog.BATTLE_CONTEXTS[wave_name]
	var context: ContextContainer = DebugActions.build_battle_context(
		player_characters, battle_context, int(_difficulty_spin.value), DebugCatalog.MAIN_MENU_SCENE_UID)
	main.GetInstance().change_scene(context)
