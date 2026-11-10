class_name AdventureGraphUi extends Control

signal node_selected(p_node: NodeData)

const GroundScene := preload("res://Scripts/UI/Adventure/adventure_ground.gd")
const EdgeLayerScene := preload("res://Scripts/UI/Adventure/adventure_edge_layer.gd")
const BackgroundScene := preload("res://Scripts/UI/Adventure/adventure_background.gd")

@export var _node_ui_scene: PackedScene
@export var _scroll_container: ScrollContainer
@export var _graph_canvas: Control
## Holds ambient effects that stay fixed on screen while the map scrolls beneath them.
@export var _screen_effects_layer: Control

var _node_positions: Dictionary = {}
var _visual_data: BiomeVisualData
var _generation_seed: int = -1
var _structure_layout: StructureLayout

func SetBiomeVisuals(p_visual_data: BiomeVisualData, p_generation_seed: int) -> void:
	_visual_data = p_visual_data
	_generation_seed = p_generation_seed

func GetStructureLayout() -> StructureLayout:
	return _structure_layout

func GetGraphCanvas() -> Control:
	return _graph_canvas

func Populate(p_nodes: Array[NodeData]) -> void:
	for child in _graph_canvas.get_children():
		child.queue_free()
	for child in _screen_effects_layer.get_children():
		child.queue_free()
	_node_positions.clear()

	await get_tree().process_frame

	var canvas_width: float = maxf(500.0, _scroll_container.size.x)
	var canvas_height: float = AdventureNodePlacement.CanvasHeight(p_nodes)
	_graph_canvas.custom_minimum_size = Vector2(canvas_width, canvas_height)
	var vertical_jitter: float = AdventureNodePlacement.DEFAULT_VERTICAL_JITTER
	if _visual_data != null and _visual_data.structure_layout != null:
		vertical_jitter = _visual_data.structure_layout.node_vertical_jitter
	_node_positions.merge(AdventureNodePlacement.PlaceNodes(p_nodes, canvas_width, vertical_jitter))

	if _visual_data != null:
		var ground := GroundScene.new()
		_graph_canvas.add_child(ground)
		ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ground.Generate(_visual_data, _generation_seed)

	_structure_layout = StructureLayoutGenerator.Build(
			_visual_data, p_nodes, _node_positions, Vector2(canvas_width, canvas_height), _generation_seed)
	var edge_layer := EdgeLayerScene.new()
	_graph_canvas.add_child(edge_layer)
	edge_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge_layer.configure(_visual_data, _generation_seed)
	edge_layer.set_roads(_structure_layout)

	if _visual_data != null:
		var background: AdventureBackground = BackgroundScene.new()
		_graph_canvas.add_child(background)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.Generate(_visual_data, _node_positions, _generation_seed, _structure_layout)
		_AddAmbientEffects(Vector2(canvas_width, canvas_height))

	var eligible_y: float = canvas_height
	for node in p_nodes:
		var is_eligible: bool = node.IsEligible()
		var node_ui: AdventureNodeUi = _node_ui_scene.instantiate()
		_graph_canvas.add_child(node_ui)
		node_ui.position = _node_positions[node]
		node_ui.Init(node, is_eligible)
		node_ui.node_selected.connect(node_selected.emit)
		if is_eligible and not node.is_complete:
			eligible_y = minf(eligible_y, _node_positions[node].y)

	await get_tree().process_frame
	_scroll_container.scroll_vertical = int(eligible_y - _scroll_container.size.y * 0.6)


func _AddAmbientEffects(p_map_size: Vector2) -> void:
	for effect_scene: PackedScene in _visual_data.ambient_effects:
		if effect_scene == null:
			continue
		var instance: Node = effect_scene.instantiate()
		var effect := instance as AdventureAmbientEffect
		if effect == null:
			push_error("Ambient effect %s is not rooted in AdventureAmbientEffect." % effect_scene.resource_path)
			instance.free()
			continue
		if effect.follows_map:
			_graph_canvas.add_child(effect)
			effect.FitToMap(p_map_size)
		else:
			_screen_effects_layer.add_child(effect)
