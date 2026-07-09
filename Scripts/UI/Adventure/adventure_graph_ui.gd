class_name AdventureGraphUi extends Control

signal node_selected(p_node: NodeData)

const GroundGradientScene := preload("res://Scripts/UI/Adventure/adventure_ground_gradient.gd")
const EdgeLayerScene := preload("res://Scripts/UI/Adventure/adventure_edge_layer.gd")
const BackgroundScene := preload("res://Scripts/UI/Adventure/adventure_background.gd")
const CloudShadowsScene := preload("res://Scenes/Adventure_Scenes/Adventure_Cloud_Shadows.tscn")
## Baseline amount the scene ships with, tuned for one screen height. Scaled up with the
## generated canvas height so deep adventures don't read as empty above/below the fold.
const CLOUD_SHADOWS_AMOUNT_PER_HEIGHT: float = 6.0 / 720.0
## Extends the emission box past the canvas's left edge so clouds are sometimes already
## drifting in from off-screen instead of only ever appearing already inside view.
const CLOUD_SHADOWS_LEFT_SPAWN_MARGIN: float = 400.0
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
		var ground_gradient := GroundGradientScene.new()
		_graph_canvas.add_child(ground_gradient)
		ground_gradient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ground_gradient.Generate(_visual_data)

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

	## Scrolls with the map (child of `_graph_canvas`, not a fixed screen overlay), so it
	## needs re-instancing every Populate and sizing to the generated canvas, which varies
	## with adventure depth — unlike the fixed-size hub backgrounds this scene's precedent
	## (the falling-leaves node) was built for.
	var cloud_shadows: GPUParticles2D = CloudShadowsScene.instantiate()
	_graph_canvas.add_child(cloud_shadows)
	cloud_shadows.amount = int(clamp(canvas_height * CLOUD_SHADOWS_AMOUNT_PER_HEIGHT, 6.0, 40.0))

	var cloud_material: ParticleProcessMaterial = cloud_shadows.process_material as ParticleProcessMaterial
	var emission_width: float = canvas_width + CLOUD_SHADOWS_LEFT_SPAWN_MARGIN
	var emission_center: Vector2 = Vector2((canvas_width - CLOUD_SHADOWS_LEFT_SPAWN_MARGIN) * 0.5, canvas_height * 0.5)
	cloud_shadows.position = emission_center
	cloud_material.emission_shape_scale = Vector3(emission_width, canvas_height, 1.0) * 0.5

	## visibility_rect is local to the node and must cover the full emission area plus a
	## margin for how far a scaled-up particle sprite extends past its own center — both
	## vary per adventure (canvas height) and per current tuning (scale_max), so this is
	## computed here rather than left as the fixed value the scene ships with, which would
	## otherwise clip particles once the canvas grows taller or the sprite scale grows.
	var canvas_material: CanvasItemMaterial = cloud_shadows.material as CanvasItemMaterial
	var frame_count: float = maxf(1.0, float(canvas_material.particles_anim_h_frames))
	var frame_size: Vector2 = cloud_shadows.texture.get_size() / Vector2(frame_count, 1.0)
	var particle_margin: float = frame_size.length() * 0.5 * cloud_material.scale_max
	var visibility_half_size: Vector2 = Vector2(emission_width, canvas_height) * 0.5 + Vector2.ONE * particle_margin
	cloud_shadows.visibility_rect = Rect2(-visibility_half_size, visibility_half_size * 2.0)

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
