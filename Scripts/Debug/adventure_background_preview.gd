class_name AdventureBackgroundPreview extends Control

## Development scene for trying adventure backgrounds: generates an adventure from a chosen
## AdventureData and seed and shows its map through the game's own AdventureGraphUi.
## Run with F6. Left/Right step the seed, R rolls a random seed, T cycles adventures,
## 0-3 set the branching frequency (none, low, medium, high), L toggles lot outlines.

@export var _adventures: Array[AdventureData]
@export var _seed: int = 1
@export var _graph_ui: AdventureGraphUi
@export var _info_label: Label
@export var _lot_overlay: StructureLayoutOverlay

var _adventure_index: int = 0
var _branching: AdventureLayout.Mechanic_Frequency = AdventureLayout.Mechanic_Frequency.MEDIUM
var _is_building: bool = false
var _seed_roller := RandomNumberGenerator.new()


func _ready() -> void:
	_seed_roller.randomize()
	if _adventures.is_empty():
		_info_label.text = "Assign adventures to preview in the inspector."
		return
	_branching = _adventures[0].layout.branching_paths
	_Rebuild()


func _unhandled_key_input(p_event: InputEvent) -> void:
	var key_event := p_event as InputEventKey
	if key_event == null or not key_event.pressed or _adventures.is_empty():
		return
	match key_event.keycode:
		KEY_LEFT:
			_seed -= 1
		KEY_RIGHT:
			_seed += 1
		KEY_R:
			_seed = _seed_roller.randi_range(0, 999999)
		KEY_T:
			_adventure_index = (_adventure_index + 1) % _adventures.size()
		KEY_0, KEY_1, KEY_2, KEY_3:
			_branching = (key_event.keycode - KEY_0) as AdventureLayout.Mechanic_Frequency
		KEY_L:
			_lot_overlay.visible = not _lot_overlay.visible
			get_viewport().set_input_as_handled()
			return
		_:
			return
	get_viewport().set_input_as_handled()
	_Rebuild()


func _Rebuild() -> void:
	if _is_building:
		return
	_is_building = true
	# Duplicated so the branching override never writes into the shared resources.
	var adventure: AdventureData = _adventures[_adventure_index].duplicate()
	adventure.layout = adventure.layout.duplicate()
	adventure.layout.branching_paths = _branching
	seed(_seed)
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(adventure)
	var visual_data: BiomeVisualData = adventure.biome.visual_data if adventure.biome != null else null
	_graph_ui.SetBiomeVisuals(visual_data, _seed)
	await _graph_ui.Populate(nodes)
	_lot_overlay.Show(_graph_ui.GetStructureLayout(), _graph_ui.GetGraphCanvas())
	_info_label.text = "%s   seed %d   branching %s\n←/→ seed   R random   T adventure   0-3 branching   L lots" % [
		adventure.display_name, _seed, AdventureLayout.Mechanic_Frequency.keys()[_branching]]
	_is_building = false
