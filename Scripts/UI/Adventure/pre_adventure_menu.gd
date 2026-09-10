extends Control

const DEFAULT_ACT: ActData = preload("res://Data/Adventure_Data/Acts/act_reclaimed_city.tres")

const REST_STRETCH_RATIO: float = 1.0
const EXPANDED_STRETCH_RATIO: float = 1.2
const SPLIT_TWEEN_SECONDS: float = 0.5

@export var _difficulty_option: OptionButton
@export var _panel_left: BiomeSelectionPanel
@export var _panel_right: BiomeSelectionPanel

var _panels: Array[BiomeSelectionPanel] = []
var _act: ActData
var _selected_index: int = 0
var _self_context: ContextContainer
var _split_tween: Tween

func Init(p_context: ContextContainer) -> void:
	_self_context = p_context
	_act = p_context._arguments.get("Act", DEFAULT_ACT)
	if _act == null:
		_act = DEFAULT_ACT
	_panels.assign([_panel_left, _panel_right])
	for i in range(_panels.size()):
		_panels[i].Populate(_act.biome_entries[i])
		_panels[i].pressed.connect(_on_panel_pressed)
		_panels[i].hover_changed.connect(_on_panel_hover_changed)

	var handler: AdventureStateHandler = main.GetInstance()._adventure_state_handler
	if handler._state.is_active:
		var active_index: int = _act.FindEntryIndexForBiome(handler._state.biome)
		_selected_index = active_index if active_index != -1 else 0
		_difficulty_option.disabled = true
		for panel in _panels:
			panel.SetInteractive(false)
	else:
		_selected_index = 0
	_ApplySelection()
	_RefreshDifficultyOptions()

func _ApplySelection() -> void:
	for i in range(_panels.size()):
		_panels[i].SetSelected(i == _selected_index)
	_ApplySplit(_selected_index)

func _ApplySplit(p_expanded_index: int) -> void:
	if _split_tween:
		_split_tween.kill()
	_split_tween = create_tween()
	_split_tween.set_parallel(true)
	for i in range(_panels.size()):
		var target: float = EXPANDED_STRETCH_RATIO if i == p_expanded_index else REST_STRETCH_RATIO
		_split_tween.tween_property(_panels[i], "size_flags_stretch_ratio", target, SPLIT_TWEEN_SECONDS)

func _RefreshDifficultyOptions() -> void:
	_difficulty_option.clear()
	var biome: BiomeData = _act.biome_entries[_selected_index].biome
	var max_diff: int = main.GetInstance()._progress.GetCurrentEncounterDifficulty(biome.resource_path)
	for i in range(1, max_diff + 1):
		_difficulty_option.add_item("Difficulty " + str(i), i)
	_difficulty_option.select(_difficulty_option.item_count - 1)
	_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()

func _on_panel_pressed(p_panel: BiomeSelectionPanel) -> void:
	var index: int = _panels.find(p_panel)
	if index == -1 or index == _selected_index:
		return
	_selected_index = index
	_ApplySelection()
	_RefreshDifficultyOptions()

func _on_panel_hover_changed(p_panel: BiomeSelectionPanel, p_is_hovered: bool) -> void:
	var index: int = _panels.find(p_panel)
	if index == -1:
		return
	if p_is_hovered:
		_ApplySplit(index)
	else:
		_ApplySplit(_selected_index)

func _on_difficulty_item_selected(_index: int) -> void:
	_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()

func _on_start_button_up() -> void:
	var handler: AdventureStateHandler = main.GetInstance()._adventure_state_handler
	if not handler._state.is_active:
		var biome: BiomeData = _act.biome_entries[_selected_index].biome
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
	context_container._arguments["Act"] = _act
	context_container._scene = "uid://mtv6bnpp8kjx"
	main.GetInstance().change_scene(context_container)

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = _self_context._previous_scene
	main.GetInstance().change_scene(context_container)
