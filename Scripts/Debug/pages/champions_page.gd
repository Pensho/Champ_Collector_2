extends DebugPage

const MAX_LEVEL: int = 100

@export var _available_list: VBoxContainer
@export var _roster_list: VBoxContainer

func _ready() -> void:
	page_title = "Champions"
	PopulateAvailableList()

func Refresh() -> void:
	PopulateRosterList()

func PopulateAvailableList() -> void:
	for catalog in [DebugCatalog.PLAYER_CHARACTER_PRESETS, DebugCatalog.ENEMY_CHARACTER_PRESETS]:
		for preset_name in catalog.keys():
			var row: HBoxContainer = HBoxContainer.new()
			var label: Label = Label.new()
			label.text = preset_name
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var add_button: Button = Button.new()
			add_button.text = "Add to Roster"
			add_button.pressed.connect(_on_add_preset_pressed.bind(catalog[preset_name]))
			row.add_child(label)
			row.add_child(add_button)
			_available_list.add_child(row)

func PopulateRosterList() -> void:
	for child in _roster_list.get_children():
		child.queue_free()
	var collection: CharacterCollection = main.GetInstance()._character_collection
	for instance_id in collection.GetAllCharacters().keys():
		var character: Character = collection.GetCharacter(instance_id)
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = character._name + " (ID " + str(instance_id) + ")"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var level_spin: SpinBox = SpinBox.new()
		level_spin.min_value = 1
		level_spin.max_value = MAX_LEVEL
		level_spin.value = character._level
		level_spin.value_changed.connect(_on_level_changed.bind(instance_id))
		var remove_button: Button = Button.new()
		remove_button.text = "Remove"
		remove_button.pressed.connect(_on_remove_pressed.bind(instance_id))
		row.add_child(label)
		row.add_child(level_spin)
		row.add_child(remove_button)
		_roster_list.add_child(row)

func _on_add_preset_pressed(p_preset: CharacterPreset) -> void:
	main.GetInstance()._character_collection.Add(p_preset.duplicate(true))
	PopulateRosterList()

func _on_level_changed(p_value: float, p_instance_id: int) -> void:
	var character: Character = main.GetInstance()._character_collection.GetCharacter(p_instance_id)
	if(null != character):
		character._level = int(p_value)

func _on_remove_pressed(p_instance_id: int) -> void:
	main.GetInstance()._character_collection.Remove(p_instance_id)
	PopulateRosterList()
