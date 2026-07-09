extends Control

const BIOME_RESOURCES: Array[BiomeData] = [
	preload("res://Data/Adventure_Data/Biome_Types/biome_reclaimed_city.tres"), # biome_reclaimed_city
]

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
	for biome in BIOME_RESOURCES:
		if biome == null:
			continue
		_biomes.append(biome)
		var label: String = biome.resource_path.get_file().get_basename().replace("_", " ")
		_biome_option.add_item(label, _biomes.size() - 1)

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
	var context_container: ContextContainer = ContextContainer.new()
	context_container._adventure_state = handler._state
	context_container._previous_scene = "uid://mtv6bnpp8kjx"
	context_container._arguments["Hub_Scene"] = _self_context._previous_scene
	context_container._scene = "uid://mtv6bnpp8kjx"
	main.GetInstance().change_scene(context_container)

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = _self_context._previous_scene
	main.GetInstance().change_scene(context_container)
