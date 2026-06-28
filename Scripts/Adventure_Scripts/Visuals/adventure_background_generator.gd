class_name AdventureBackgroundGenerator extends Node

## Pure static pipeline that turns a BiomeVisualData + the laid-out node positions into a
## flat list of DecorPlacement, deterministic for a given seed. No nodes, no drawing —
## mirrors AdventureGenerator.GenerateAdventure so it stays fully unit-testable.
##
## Tier A (region grid): a low-frequency region_noise sample per coarse cell picks a
## BiomeRegionData zone via cumulative selection_weight, so neighbouring cells fall in
## the same band and form contiguous regions.
## Tier B (placement grid): each fine cell looks up its parent zone, jitters one candidate
## point, and for every zone decor entry rolls density + detail_noise threshold to decide
## whether to place an element.

## Node-type props must always read as "what's here" at a glance, so they are drawn above
## every decor layer regardless of the layer's own z_index.
const NODE_PROP_Z_INDEX: int = 1000

static func Generate(p_visual_data: BiomeVisualData, p_canvas_size: Vector2, p_node_positions: Dictionary, p_seed: int) -> Array[DecorPlacement]:
	var placements: Array[DecorPlacement] = []
	if p_visual_data == null or p_visual_data.regions.is_empty():
		return placements

	p_visual_data.region_noise.seed = p_seed
	p_visual_data.detail_noise.seed = p_seed

	var node_position_list: Array[Vector2] = []
	for node in p_node_positions:
		node_position_list.append(p_node_positions[node])

	var coarse_size: float = maxf(p_visual_data.coarse_cell_size, 1.0)
	var fine_size: float = maxf(p_visual_data.fine_cell_size, 1.0)
	var fine_columns: int = ceili(p_canvas_size.x / fine_size)
	var fine_rows: int = ceili(p_canvas_size.y / fine_size)

	for fine_row in fine_rows:
		for fine_column in fine_columns:
			var cell_origin: Vector2 = Vector2(fine_column * fine_size, fine_row * fine_size)
			var coarse_x: int = int(cell_origin.x / coarse_size)
			var coarse_y: int = int(cell_origin.y / coarse_size)
			var zone: BiomeRegionData = _PickZone(p_visual_data, coarse_x, coarse_y)
			if zone == null:
				continue

			var cell_rng := RandomNumberGenerator.new()
			cell_rng.seed = _HashCellSeed(p_seed, fine_column, fine_row)
			var candidate_point: Vector2 = cell_origin + Vector2(
				cell_rng.randf_range(0.0, fine_size),
				cell_rng.randf_range(0.0, fine_size)
			)

			for entry in zone.decor:
				var layer: DecorLayerData = entry.layer
				if layer == null:
					continue
				var zone_density: float = clampf(layer.density * entry.density_multiplier, 0.0, 1.0)
				if cell_rng.randf() > zone_density:
					continue
				var detail_sample: float = p_visual_data.detail_noise.get_noise_2d(candidate_point.x, candidate_point.y)
				detail_sample = (detail_sample + 1.0) * 0.5
				if detail_sample < layer.noise_threshold_min or detail_sample > layer.noise_threshold_max:
					continue
				if layer.avoid_radius > 0.0 and _IsTooCloseToNode(candidate_point, node_position_list, layer.avoid_radius):
					continue
				placements.append(_BuildPlacement(layer, candidate_point, cell_rng, zone.tint))

	_AppendNodeProps(p_visual_data, p_node_positions, p_seed, p_canvas_size, placements)

	placements.sort_custom(_SortByZThenY)
	return placements


static func _PickZone(p_visual_data: BiomeVisualData, p_coarse_x: int, p_coarse_y: int) -> BiomeRegionData:
	var sample_position: Vector2 = Vector2(p_coarse_x, p_coarse_y) * p_visual_data.coarse_cell_size
	var noise_sample: float = p_visual_data.region_noise.get_noise_2d(sample_position.x, sample_position.y)
	noise_sample = clampf((noise_sample + 1.0) * 0.5, 0.0, 1.0)

	var total_weight: float = 0.0
	for region in p_visual_data.regions:
		total_weight += region.selection_weight
	if total_weight <= 0.0:
		return null

	var target: float = noise_sample * total_weight
	var cumulative: float = 0.0
	for region in p_visual_data.regions:
		cumulative += region.selection_weight
		if target <= cumulative:
			return region
	return p_visual_data.regions[-1]


static func _IsTooCloseToNode(p_point: Vector2, p_node_positions: Array[Vector2], p_radius: float) -> bool:
	for node_position in p_node_positions:
		if p_point.distance_to(node_position) < p_radius:
			return true
	return false


static func _BuildPlacement(p_layer: DecorLayerData, p_point: Vector2, p_rng: RandomNumberGenerator, p_zone_tint: Color) -> DecorPlacement:
	var placement := DecorPlacement.new()
	placement.texture = p_layer.textures[p_rng.randi_range(0, p_layer.textures.size() - 1)] if not p_layer.textures.is_empty() else null
	placement.position = p_point
	placement.scale = p_rng.randf_range(p_layer.scale_min, p_layer.scale_max)
	placement.rotation_degrees = p_rng.randf_range(-p_layer.rotation_jitter_degrees, p_layer.rotation_jitter_degrees)
	placement.flip_h = p_layer.allow_horizontal_flip and p_rng.randf() < 0.5
	placement.tint = p_layer.tint * p_zone_tint
	placement.z_index = p_layer.z_index
	return placement


static func _AppendNodeProps(p_visual_data: BiomeVisualData, p_node_positions: Dictionary, p_seed: int, p_canvas_size: Vector2, p_placements: Array[DecorPlacement]) -> void:
	for node: NodeData in p_node_positions:
		if not p_visual_data.node_props.has(node.node_type):
			continue
		var texture: Texture2D = p_visual_data.node_props[node.node_type]
		if texture == null:
			continue
		var node_rng := RandomNumberGenerator.new()
		node_rng.seed = _HashCellSeed(p_seed, node.index, node.node_type)
		var offset: Vector2 = Vector2(node_rng.randf_range(40.0, 70.0), node_rng.randf_range(-20.0, 20.0))
		var placement := DecorPlacement.new()
		placement.texture = texture
		placement.position = _ClampPropPosition(p_node_positions[node] + offset, texture.get_size(), p_canvas_size)
		placement.scale = 1.0
		placement.z_index = NODE_PROP_Z_INDEX
		p_placements.append(placement)


## Node props pivot bottom-centre (see adventure_background.gd), so the texture rect spans
## [position.x - half_width, position.x + half_width] horizontally and
## [position.y - height, position.y] vertically; clamp position so that rect stays
## entirely within the canvas instead of bleeding off an edge.
static func _ClampPropPosition(p_position: Vector2, p_texture_size: Vector2, p_canvas_size: Vector2) -> Vector2:
	var half_width: float = p_texture_size.x * 0.5
	var clamped_x: float = clampf(p_position.x, half_width, maxf(half_width, p_canvas_size.x - half_width))
	var clamped_y: float = clampf(p_position.y, p_texture_size.y, maxf(p_texture_size.y, p_canvas_size.y))
	return Vector2(clamped_x, clamped_y)


static func _HashCellSeed(p_seed: int, p_x: int, p_y: int) -> int:
	return hash([p_seed, p_x, p_y])


static func _SortByZThenY(p_a: DecorPlacement, p_b: DecorPlacement) -> bool:
	if p_a.z_index != p_b.z_index:
		return p_a.z_index < p_b.z_index
	return p_a.position.y < p_b.position.y
