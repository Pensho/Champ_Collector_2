class_name AdventureGraphUi extends Control

signal node_selected(p_node: NodeData)

@export var _node_ui_scene: PackedScene
@export var _scroll_container: ScrollContainer
@export var _graph_canvas: Control

const EdgeLayerScene := preload("res://Scripts/UI/Adventure/adventure_edge_layer.gd")
const BackgroundScene := preload("res://Scripts/UI/Adventure/adventure_background.gd")
const LAYER_HEIGHT: int = 180
const NODE_SIZE:    int = 80
const PADDING:      int = 30
const JITTER_MAX:   int = 55
const JITTER_Y_MAX: int = 45

var _node_positions: Dictionary = {}
var _visual_data: BiomeVisualData
var _generation_seed: int = -1

func SetBiomeVisuals(p_visual_data: BiomeVisualData, p_generation_seed: int) -> void:
	_visual_data = p_visual_data
	_generation_seed = p_generation_seed

func Populate(p_nodes: Array[NodeData]) -> void:
	for child in _graph_canvas.get_children():
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
	var canvas_height: float = (max_depth + 1) * LAYER_HEIGHT + PADDING * 2
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
			var y: float         = (max_depth - node.depth) * LAYER_HEIGHT + PADDING + jitter_y
			_node_positions[node] = Vector2(x, y)

	if _visual_data != null:
		var background: AdventureBackground = BackgroundScene.new()
		_graph_canvas.add_child(background)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.Generate(_visual_data, _node_positions, _generation_seed)

	var edges: Array = []
	for node in p_nodes:
		for next: NodeData in node.next_node:
			edges.append([_node_positions[node], _node_positions[next]])

	var edge_layer := EdgeLayerScene.new()
	_graph_canvas.add_child(edge_layer)
	edge_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge_layer.set_edges(edges)

	var eligible_y: float = canvas_height
	for node in p_nodes:
		var is_eligible: bool = _IsEligible(node)
		var node_ui: AdventureNodeUi = _node_ui_scene.instantiate()
		_graph_canvas.add_child(node_ui)
		node_ui.position = _node_positions[node]
		node_ui.Init(node, is_eligible)
		node_ui.node_selected.connect(node_selected.emit)
		if is_eligible and not node.is_complete:
			eligible_y = minf(eligible_y, _node_positions[node].y)

	await get_tree().process_frame
	_scroll_container.scroll_vertical = int(eligible_y - _scroll_container.size.y * 0.6)

func _IsEligible(p_node: NodeData) -> bool:
	if p_node.previous_node.is_empty():
		return true
	for prev in p_node.previous_node:
		if prev.is_complete:
			return true
	return false
