extends Control

@export var _difficulty_option: OptionButton
@export var _biome_option: OptionButton

var _biomes: Array[BiomeData] = []
var _self_context: ContextContainer

func Init(p_context: ContextContainer) -> void:
	_self_context = p_context
	_LoadBiomes()
	_RefreshDifficultyOptions()

	var handler: AdventureStateHandler = main.GetInstance()._adventure_state_handler
	if handler._state.is_active:
		_biome_option.disabled = true
		_difficulty_option.disabled = true

func _RefreshDifficultyOptions() -> void:
	_difficulty_option.clear()
	if _biomes.is_empty():
		return
	var biome: BiomeData = _biomes[_biome_option.selected]
	var max_diff: int = main.GetInstance()._progress.GetCurrentEncounterDifficulty(biome.resource_path)
	for i in range(1, max_diff + 1):
		_difficulty_option.add_item("Difficulty " + str(i), i)
	_difficulty_option.select(_difficulty_option.item_count - 1)
	_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()

func _LoadBiomes() -> void:
	var dir := DirAccess.open("res://Data/Adventure_Data/Biome_Types/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var biome: BiomeData = load("res://Data/Adventure_Data/Biome_Types/" + file_name)
			if biome != null:
				_biomes.append(biome)
				_biome_option.add_item(file_name.get_basename().replace("_", " "), _biomes.size() - 1)
		file_name = dir.get_next()

func _on_biome_item_selected(_index: int) -> void:
	_RefreshDifficultyOptions()

func _on_difficulty_item_selected(_index: int) -> void:
	_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()

func _on_start_button_up() -> void:
	var handler: AdventureStateHandler = main.GetInstance()._adventure_state_handler
	if not handler._state.is_active:
		if _biomes.is_empty():
			push_warning("No biomes loaded — cannot start adventure.")
			return
		var biome: BiomeData = _biomes[_biome_option.selected]
		var template: AdventureTemplate = load("res://Data/Adventure_Data/template_default.tres")
		template.difficulty = _self_context._arguments.get("Difficulty", 1)
		var state: AdventureState = AdventureState.new()
		state.biome = biome
		state.template = template
		state.difficulty = template.difficulty
		state._generation_seed = randi()
		seed(state._generation_seed)
		state.nodes = AdventureGenerator.GenerateAdventure(template, biome)
		state.is_active = true
		handler._state = state
	var cc: ContextContainer = ContextContainer.new()
	cc._adventure_state = handler._state
	cc._previous_scene = "uid://mtv6bnpp8kjx"
	cc._arguments["Hub_Scene"] = _self_context._previous_scene
	cc._scene = "uid://mtv6bnpp8kjx"
	main.GetInstance().change_scene(cc)

func _on_exit_button_up() -> void:
	var cc: ContextContainer = ContextContainer.new()
	cc._scene = _self_context._previous_scene
	main.GetInstance().change_scene(cc)
