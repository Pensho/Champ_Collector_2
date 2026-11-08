class_name AdventureGraphUi extends Control

signal node_selected(p_node: NodeData)

const GroundScene := preload("res://Scripts/UI/Adventure/adventure_ground.gd")
const EdgeLayerScene := preload("res://Scripts/UI/Adventure/adventure_edge_layer.gd")
const BackgroundScene := preload("res://Scripts/UI/Adventure/adventure_background.gd")
const LAYER_HEIGHT: int = 180
const NODE_SIZE:    int = 80
const PADDING:      int = 30
const JITTER_MAX:   int = 55
const JITTER_Y_MAX: int = 45
## Empty map kept above the boss (last) node so it has the same decorated run-off as the
## space below the first node. One extra layer past the boss, mirroring the bottom margin.
const END_MARGIN: int = LAYER_HEIGHT

@export var _node_ui_scene: PackedScene
@export var _scroll_container: ScrollContainer
@export var _graph_canvas: Control
## Holds ambient effects that stay fixed on screen while the map scrolls beneath them.
@export var _screen_effects_layer: Control

var _node_positions: Dictionary = {}
var _visual_data: BiomeVisualData
var _generation_seed: int = -1

func SetBiomeVisuals(p_visual_data: BiomeVisualData, p_generation_seed: int) -> void:
	_visual_data = p_visual_data
	_generation_seed = p_generation_seed

func Populate(p_nodes: Array[NodeData]) -> void:
	for child in _graph_canvas.get_children():
		child.queue_free()
	for child in _screen_effects_layer.get_children():
		child.queue_free()
	_node_positions.clear()

	var by_depth: Dictionary = {}
	var max_depth: int = 0
	for node in p_nodes:
		if not by_depth.has(node.depth):
			by_depth[node.depth] = []
		by_depth[node.depth].append(node)
		if node.depth > max_depth:
			max_depth = node.depth

	await get_tree().process_frame

	var canvas_width: float  = max(500.0, _scroll_container.size.x)
	var canvas_height: float = (max_depth + 1) * LAYER_HEIGHT + PADDING * 2 + END_MARGIN
	_graph_canvas.custom_minimum_size = Vector2(canvas_width, canvas_height)

	for depth in by_depth:
		var nodes_at_depth: Array = by_depth[depth]
		var count: int = nodes_at_depth.size()
		for i: int in range(count):
			var node: NodeData = nodes_at_depth[i]
			var slot_width: float = canvas_width / (count + 1)
			var base_x: float    = (i + 1) * slot_width - NODE_SIZE / 2.0
			var rng := RandomNumberGenerator.new()
			rng.seed = node.index
			var jitter_x: float  = rng.randf_range(-JITTER_MAX, JITTER_MAX)
			var jitter_y: float  = rng.randf_range(-JITTER_Y_MAX, JITTER_Y_MAX)
			var x: float         = clampf(base_x + jitter_x, PADDING, canvas_width - NODE_SIZE - PADDING)
			var y: float         = (max_depth - node.depth) * LAYER_HEIGHT + PADDING + END_MARGIN + jitter_y
			_node_positions[node] = Vector2(x, y)

	if _visual_data != null:
		var ground := GroundScene.new()
		_graph_canvas.add_child(ground)
		ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ground.Generate(_visual_data, _generation_seed)

	var edges: Array = []
	for node in p_nodes:
		for next: NodeData in node.next_node:
			edges.append([_node_positions[node], _node_positions[next], node.index, next.index])

	var edge_layer := EdgeLayerScene.new()
	_graph_canvas.add_child(edge_layer)
	edge_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge_layer.configure(_visual_data, _generation_seed)
	edge_layer.set_edges(edges)

	if _visual_data != null:
		var background: AdventureBackground = BackgroundScene.new()
		_graph_canvas.add_child(background)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.Generate(_visual_data, _node_positions, _generation_seed)
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
