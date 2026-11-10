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

## Minimum clearance between a cluster prop's grown footprint and any node's 80×80 rect.
## Smaller than layer.node_avoidance_radius so the ring forms close around the node icon.
const NODE_PROP_CLEARANCE: float = 6.0

## Mirrors AdventureNodePlacement.NODE_SIZE; stored node positions are the node's top-left
## corner, so the visual centre is position + (NODE_HALF_SIZE, NODE_HALF_SIZE).
const NODE_HALF_SIZE: float = 40.0

## Absorbs float error so a side exactly n spacings long fits n pieces, not n - 1.
const EDGE_FIT_TOLERANCE: float = 0.001
## Rows of blocking rects are bucketed this tall when testing street candidates.
const STREET_BUCKET_HEIGHT: float = 64.0

static func Generate(
		p_visual_data: BiomeVisualData,
		p_canvas_size: Vector2,
		p_node_positions: Dictionary,
		p_seed: int,
		p_layout: StructureLayout = null) -> Array[DecorPlacement]:
	var placements: Array[DecorPlacement] = []
	if p_visual_data == null or p_visual_data.regions.is_empty():
		return placements

	p_visual_data.region_noise.seed = p_seed
	p_visual_data.detail_noise.seed = p_seed

	var node_center_list: Array[Vector2] = []
	for node in p_node_positions:
		node_center_list.append(p_node_positions[node] + Vector2(NODE_HALF_SIZE, NODE_HALF_SIZE))

	if p_layout != null and p_visual_data.structure_layout != null:
		_AppendLotDecor(p_visual_data, p_layout, p_seed, node_center_list, placements)
		var street_region: BiomeRegionData = p_visual_data.structure_layout.street_region
		if street_region != null:
			var blocked_buckets: Dictionary[int, Array] = _BucketStreetBlockers(p_visual_data, p_layout)
			_AppendGridDecor(p_visual_data, p_canvas_size, p_seed, node_center_list, placements,
					func(_p_coarse_x: int, _p_coarse_y: int, p_point: Vector2) -> BiomeRegionData:
						return null if _IsBlocked(p_point, blocked_buckets) else street_region)
	else:
		_AppendGridDecor(p_visual_data, p_canvas_size, p_seed, node_center_list, placements,
				func(p_coarse_x: int, p_coarse_y: int, _p_point: Vector2) -> BiomeRegionData:
					return _PickZone(p_visual_data, p_coarse_x, p_coarse_y))

	if p_layout != null:
		placements.append_array(p_layout.landmarks)

	_AppendNodeProps(p_visual_data, p_node_positions, p_canvas_size, placements, p_seed, node_center_list)

	placements = _RemoveDecorOverlappingClearers(placements)
	placements.sort_custom(_SortByZThenY)
	return placements


## One jittered candidate per fine cell; p_zone_at(coarse x, coarse y, candidate) picks the
## region decorating it, null to skip. Only SCATTER layers place here.
static func _AppendGridDecor(
		p_visual_data: BiomeVisualData,
		p_canvas_size: Vector2,
		p_seed: int,
		p_node_center_list: Array[Vector2],
		p_placements: Array[DecorPlacement],
		p_zone_at: Callable) -> void:
	var coarse_size: float = maxf(p_visual_data.coarse_cell_size, 1.0)
	var fine_size: float = maxf(p_visual_data.fine_cell_size, 1.0)
	var fine_columns: int = ceili(p_canvas_size.x / fine_size)
	var fine_rows: int = ceili(p_canvas_size.y / fine_size)

	for fine_row in fine_rows:
		for fine_column in fine_columns:
			var cell_origin: Vector2 = Vector2(fine_column * fine_size, fine_row * fine_size)
			var cell_rng := RandomNumberGenerator.new()
			cell_rng.seed = _HashCellSeed(p_seed, fine_column, fine_row)
			var candidate_point: Vector2 = cell_origin + Vector2(
				cell_rng.randf_range(0.0, fine_size),
				cell_rng.randf_range(0.0, fine_size)
			)
			var zone: BiomeRegionData = p_zone_at.call(
					int(cell_origin.x / coarse_size), int(cell_origin.y / coarse_size), candidate_point)
			if zone == null:
				continue

			for entry in zone.decor:
				var layer: DecorLayerData = entry.layer
				if layer == null or layer.placement_mode != DecorLayerData.Placement_Mode.SCATTER:
					continue
				var zone_density: float = clampf(layer.density * entry.density_multiplier, 0.0, 1.0)
				if cell_rng.randf() > zone_density:
					continue
				_TryAppend(p_visual_data, _BuildPlacement(layer, candidate_point, cell_rng, zone.tint),
						layer, p_node_center_list, p_placements)


## Decorates every lot from its own region: scatter inside it, pieces along its sides and on
## its corners, and at most one fill element. Each lot rolls from its own seeded generator.
static func _AppendLotDecor(
		p_visual_data: BiomeVisualData,
		p_layout: StructureLayout,
		p_seed: int,
		p_node_center_list: Array[Vector2],
		p_placements: Array[DecorPlacement]) -> void:
	var fine_size: float = maxf(p_visual_data.fine_cell_size, 1.0)
	for lot_index in p_layout.lots.size():
		var lot: StructureLayout.Lot = p_layout.lots[lot_index]
		if lot.region == null:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([p_seed, "lot", lot_index])
		var is_filled: bool = false
		for entry in lot.region.decor:
			var layer: DecorLayerData = entry.layer
			if layer == null:
				continue
			var density: float = clampf(layer.density * entry.density_multiplier, 0.0, 1.0)
			match layer.placement_mode:
				DecorLayerData.Placement_Mode.SCATTER:
					for _candidate in roundi(lot.rect.get_area() / (fine_size * fine_size)):
						var point: Vector2 = lot.rect.position + Vector2(
								rng.randf() * lot.rect.size.x, rng.randf() * lot.rect.size.y)
						if rng.randf() > density:
							continue
						_TryAppend(p_visual_data, _BuildPlacement(layer, point, rng, lot.region.tint),
								layer, p_node_center_list, p_placements)
				DecorLayerData.Placement_Mode.LOT_EDGE, DecorLayerData.Placement_Mode.LOT_CORNER:
					var points: Array[Vector2] = (EdgePoints(lot.rect, layer)
							if layer.placement_mode == DecorLayerData.Placement_Mode.LOT_EDGE
							else CornerPoints(lot.rect, layer.edge_inset))
					for point in points:
						if rng.randf() > density:
							continue
						var placement: DecorPlacement = _BuildPlacement(layer, point, rng, lot.region.tint)
						placement.rotation_degrees = 0.0
						placement.flip_h = false
						_TryAppend(p_visual_data, placement, layer, p_node_center_list, p_placements)
				DecorLayerData.Placement_Mode.LOT_FILL:
					if is_filled or rng.randf() > density:
						continue
					var fill: DecorPlacement = BuildFillPlacement(layer, lot.rect, rng, lot.region.tint)
					if fill != null:
						is_filled = _TryAppend(p_visual_data, fill, layer, p_node_center_list, p_placements)


## Appends p_placement when the detail noise at its position lies in the layer's band and it
## keeps the layer's distance from nodes. Returns whether it was appended.
static func _TryAppend(
		p_visual_data: BiomeVisualData,
		p_placement: DecorPlacement,
		p_layer: DecorLayerData,
		p_node_center_list: Array[Vector2],
		p_placements: Array[DecorPlacement]) -> bool:
	var detail_sample: float = p_visual_data.detail_noise.get_noise_2d(p_placement.position.x, p_placement.position.y)
	detail_sample = (detail_sample + 1.0) * 0.5
	if detail_sample < p_layer.noise_threshold_min or detail_sample > p_layer.noise_threshold_max:
		return false
	if (p_layer.node_avoidance_radius > 0.0 and
			not _DecorClearsNodes(p_placement, p_node_center_list, p_layer.node_avoidance_radius)):
		return false
	p_placements.append(p_placement)
	return true


## Anchor points for a LOT_EDGE layer: pieces centred along the top and bottom sides, and
## stacked up the left and right sides from their lower ends, every edge_spacing, inside
## the lot's outline by edge_inset. The run is centred so leftover length splits evenly;
## a side that is a whole number of spacings long is covered corner to corner.
static func EdgePoints(p_rect: Rect2, p_layer: DecorLayerData) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var spacing: float = p_layer.edge_spacing
	var inner: Rect2 = p_rect.grow(-p_layer.edge_inset)
	if spacing <= 0.0 or inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return points
	var sides: Array[bool] = _EdgeSides(p_layer.edge_orientation)
	var horizontal_count: int = floori(inner.size.x / spacing + EDGE_FIT_TOLERANCE)
	var first_x: float = inner.position.x + (inner.size.x - horizontal_count * spacing) * 0.5 + spacing * 0.5
	for index in horizontal_count:
		if sides[0]:
			points.append(Vector2(first_x + index * spacing, inner.position.y))
		if sides[1]:
			points.append(Vector2(first_x + index * spacing, inner.end.y))
	if sides[2]:
		var vertical_count: int = floori(inner.size.y / spacing + EDGE_FIT_TOLERANCE)
		var lowest_y: float = inner.end.y - (inner.size.y - vertical_count * spacing) * 0.5
		for index in vertical_count:
			points.append(Vector2(inner.position.x, lowest_y - index * spacing))
			points.append(Vector2(inner.end.x, lowest_y - index * spacing))
	return points


## Whether an orientation uses the [top, bottom, left and right] sides.
static func _EdgeSides(p_orientation: DecorLayerData.Edge_Orientation) -> Array[bool]:
	match p_orientation:
		DecorLayerData.Edge_Orientation.HORIZONTAL:
			return [true, true, false]
		DecorLayerData.Edge_Orientation.VERTICAL:
			return [false, false, true]
		DecorLayerData.Edge_Orientation.TOP:
			return [true, false, false]
		DecorLayerData.Edge_Orientation.BOTTOM:
			return [false, true, false]
	return [true, true, true]


## How far a biome's LOT_EDGE pieces rise above the top of their lot: full height for
## pieces standing on the top side, height beyond one step for side pieces.
static func EdgeOverhang(p_visual_data: BiomeVisualData) -> float:
	var overhang: float = 0.0
	for region in p_visual_data.regions:
		for entry in region.decor:
			var layer: DecorLayerData = entry.layer
			if (layer == null or layer.placement_mode != DecorLayerData.Placement_Mode.LOT_EDGE
					or layer.edge_orientation == DecorLayerData.Edge_Orientation.BOTTOM):
				continue
			for texture in layer.textures:
				if texture == null:
					continue
				var height: float = texture.get_height() * maxf(layer.scale_min, layer.scale_max)
				if layer.edge_orientation == DecorLayerData.Edge_Orientation.VERTICAL:
					height -= layer.edge_spacing
				overhang = maxf(overhang, height - layer.edge_inset)
	return overhang


static func CornerPoints(p_rect: Rect2, p_inset: float) -> Array[Vector2]:
	var inner: Rect2 = p_rect.grow(-p_inset)
	if inner.size.x < 0.0 or inner.size.y < 0.0:
		return []
	return [inner.position, Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), inner.end]


## One element sized to p_rect, from the textures that fit its width (both sides for
## decals) within the layer's scale range. Props stand centred on the bottom edge; decals
## sit centred. Null when no texture fits.
static func BuildFillPlacement(
		p_layer: DecorLayerData,
		p_rect: Rect2,
		p_rng: RandomNumberGenerator,
		p_zone_tint: Color) -> DecorPlacement:
	var fitting: Array[Texture2D] = []
	for texture in p_layer.textures:
		if texture != null and _FillScaleLimit(p_layer, texture, p_rect) >= p_layer.scale_min:
			fitting.append(texture)
	if fitting.is_empty():
		return null
	var placement := DecorPlacement.new()
	placement.texture = fitting[p_rng.randi_range(0, fitting.size() - 1)]
	var largest_scale: float = minf(p_layer.scale_max, _FillScaleLimit(p_layer, placement.texture, p_rect))
	placement.scale = p_rng.randf_range(p_layer.scale_min, maxf(p_layer.scale_min, largest_scale))
	placement.flip_h = p_layer.allow_horizontal_flip and p_rng.randf() < 0.5
	placement.tint = p_layer.tint * p_zone_tint
	placement.z_index = p_layer.z_index
	placement.clears_other_decor = p_layer.clears_other_decor
	placement.position = (Vector2(p_rect.get_center().x, p_rect.end.y) if p_layer.z_index >= 0
			else p_rect.get_center())
	return placement


static func _FillScaleLimit(p_layer: DecorLayerData, p_texture: Texture2D, p_rect: Rect2) -> float:
	var limit: float = p_rect.size.x / maxf(p_texture.get_width(), 1.0)
	if p_layer.z_index < 0:
		limit = minf(limit, p_rect.size.y / maxf(p_texture.get_height(), 1.0))
	return limit


## Lots, plazas and road corridors, bucketed by STREET_BUCKET_HEIGHT rows so street
## candidates only test the rects that share their row.
static func _BucketStreetBlockers(p_visual_data: BiomeVisualData, p_layout: StructureLayout) -> Dictionary[int, Array]:
	var blockers: Array[Rect2] = p_layout.plazas.duplicate()
	for lot in p_layout.lots:
		blockers.append(lot.rect)
	for landmark in p_layout.landmarks:
		if landmark.texture != null:
			blockers.append(PlacementRect(landmark))
	blockers.append_array(StructureLayoutGenerator.RoadCorridors(
			p_layout.roads, p_visual_data.road_width, p_visual_data.structure_layout.road_clearance))
	var buckets: Dictionary[int, Array] = {}
	for blocker in blockers:
		for bucket in range(floori(blocker.position.y / STREET_BUCKET_HEIGHT),
				floori(blocker.end.y / STREET_BUCKET_HEIGHT) + 1):
			if not buckets.has(bucket):
				buckets[bucket] = []
			buckets[bucket].append(blocker)
	return buckets


static func _IsBlocked(p_point: Vector2, p_buckets: Dictionary[int, Array]) -> bool:
	for blocker: Rect2 in p_buckets.get(floori(p_point.y / STREET_BUCKET_HEIGHT), []):
		if blocker.has_point(p_point):
			return true
	return false


static func _PickZone(p_visual_data: BiomeVisualData, p_coarse_x: int, p_coarse_y: int) -> BiomeRegionData:
	return PickZoneAt(p_visual_data, Vector2(p_coarse_x, p_coarse_y) * p_visual_data.coarse_cell_size)


## The region whose cumulative selection_weight band holds region_noise at p_position.
static func PickZoneAt(p_visual_data: BiomeVisualData, p_position: Vector2) -> BiomeRegionData:
	var noise_sample: float = p_visual_data.region_noise.get_noise_2d(p_position.x, p_position.y)
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


## Tests the decor's rendered bounding box (grown by p_margin) against every node's
## footprint, matching the pivot rules used when actually drawing (see
## adventure_background.gd): bottom-centre pivot for z_index >= 0, centre pivot otherwise.
static func _DecorClearsNodes(p_placement: DecorPlacement, p_node_centers: Array[Vector2], p_margin: float) -> bool:
	if p_placement.texture == null:
		for node_center in p_node_centers:
			if p_placement.position.distance_to(node_center) < p_margin:
				return false
		return true

	var decor_rect: Rect2 = PlacementRect(p_placement).grow(p_margin)
	for node_center in p_node_centers:
		var node_rect := Rect2(
				node_center - Vector2(NODE_HALF_SIZE, NODE_HALF_SIZE), Vector2(NODE_HALF_SIZE * 2.0, NODE_HALF_SIZE * 2.0))
		if decor_rect.intersects(node_rect):
			return false
	return true


## The placement's rendered bounding box, matching the pivot rules in adventure_background.gd:
## bottom-centre pivot for z_index >= 0, centre pivot otherwise. Requires a texture.
static func PlacementRect(p_placement: DecorPlacement) -> Rect2:
	var texture_size: Vector2 = p_placement.texture.get_size()
	var half_width: float = texture_size.x * 0.5 * p_placement.scale
	var height: float = texture_size.y * p_placement.scale
	if p_placement.z_index >= 0:
		return Rect2(p_placement.position.x - half_width, p_placement.position.y - height, half_width * 2.0, height)
	return Rect2(p_placement.position.x - half_width, p_placement.position.y - height * 0.5, half_width * 2.0, height)


## Runs after generation so filtering never shifts the seeded random sequence. Clearing
## placements claim space in generation order; a later one overlapping a kept one is dropped.
static func _RemoveDecorOverlappingClearers(p_placements: Array[DecorPlacement]) -> Array[DecorPlacement]:
	var clearer_rects: Array[Rect2] = []
	var kept_clearers: Dictionary[DecorPlacement, bool] = {}
	for placement in p_placements:
		if placement.clears_other_decor and placement.texture != null:
			var placement_rect: Rect2 = PlacementRect(placement)
			if not _OverlapsAny(placement_rect, clearer_rects):
				clearer_rects.append(placement_rect)
				kept_clearers[placement] = true
	if clearer_rects.is_empty():
		return p_placements

	var kept: Array[DecorPlacement] = []
	for placement in p_placements:
		if placement.texture == null:
			kept.append(placement)
		elif placement.clears_other_decor:
			if kept_clearers.has(placement):
				kept.append(placement)
		elif not _OverlapsAny(PlacementRect(placement), clearer_rects):
			kept.append(placement)
	return kept


static func _OverlapsAny(p_rect: Rect2, p_others: Array[Rect2]) -> bool:
	for other in p_others:
		if p_rect.intersects(other):
			return true
	return false


static func _BuildPlacement(
		p_layer: DecorLayerData,
		p_point: Vector2,
		p_rng: RandomNumberGenerator,
		p_zone_tint: Color) -> DecorPlacement:
	var placement := DecorPlacement.new()
	placement.texture = (p_layer.textures[p_rng.randi_range(0, p_layer.textures.size() - 1)]
			if not p_layer.textures.is_empty() else null)
	placement.position = p_point
	placement.scale = p_rng.randf_range(p_layer.scale_min, p_layer.scale_max)
	placement.rotation_degrees = p_rng.randf_range(-p_layer.rotation_jitter_degrees, p_layer.rotation_jitter_degrees)
	placement.flip_h = p_layer.allow_horizontal_flip and p_rng.randf() < 0.5
	placement.tint = p_layer.tint * p_zone_tint
	placement.z_index = p_layer.z_index
	placement.clears_other_decor = p_layer.clears_other_decor
	return placement


static func _AppendNodeProps(
		p_visual_data: BiomeVisualData,
		p_node_positions: Dictionary,
		p_canvas_size: Vector2,
		p_placements: Array[DecorPlacement],
		p_seed: int,
		p_node_center_list: Array[Vector2]) -> void:
	for node: NodeData in p_node_positions:
		if not p_visual_data.node_props.has(node.node_type):
			continue
		var cluster: NodePropCluster = p_visual_data.node_props[node.node_type]
		if cluster == null or cluster.decor.is_empty():
			continue
		var node_center: Vector2 = p_node_positions[node] + Vector2(NODE_HALF_SIZE, NODE_HALF_SIZE)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([p_seed, node.index])
		var inner_squared: float = cluster.inner_radius * cluster.inner_radius
		var outer_squared: float = cluster.outer_radius * cluster.outer_radius
		for _i in cluster.sample_count:
			var angle: float = rng.randf() * TAU
			var radius: float = sqrt(lerp(inner_squared, outer_squared, rng.randf()))
			var candidate: Vector2 = node_center + Vector2(cos(angle), sin(angle)) * radius
			for entry in cluster.decor:
				var layer: DecorLayerData = entry.layer
				if layer == null:
					continue
				var effective_density: float = clampf(layer.density * entry.density_multiplier, 0.0, 1.0)
				if rng.randf() > effective_density:
					continue
				var detail_sample: float = p_visual_data.detail_noise.get_noise_2d(candidate.x, candidate.y)
				detail_sample = (detail_sample + 1.0) * 0.5
				if detail_sample < layer.noise_threshold_min or detail_sample > layer.noise_threshold_max:
					continue
				var placement: DecorPlacement = _BuildPlacement(layer, candidate, rng, Color.WHITE)
				placement.z_index = NODE_PROP_Z_INDEX
				if not _DecorClearsNodes(placement, p_node_center_list, NODE_PROP_CLEARANCE):
					continue
				if placement.texture != null:
					var rendered_size: Vector2 = placement.texture.get_size() * placement.scale
					placement.position = _ClampPropPosition(placement.position, rendered_size, p_canvas_size)
				p_placements.append(placement)


## Node props pivot bottom-centre (see adventure_background.gd), so the texture rect spans
## [position.x - half_width, position.x + half_width] horizontally and
## [position.y - height, position.y] vertically; clamp position so that rect stays
## entirely within the canvas instead of bleeding off an edge. p_rendered_size is the
## texture's native pixel size — node props render at scale 1.0.
static func _ClampPropPosition(p_position: Vector2, p_rendered_size: Vector2, p_canvas_size: Vector2) -> Vector2:
	var half_width: float = p_rendered_size.x * 0.5
	var clamped_x: float = clampf(p_position.x, half_width, maxf(half_width, p_canvas_size.x - half_width))
	var clamped_y: float = clampf(p_position.y, p_rendered_size.y, maxf(p_rendered_size.y, p_canvas_size.y))
	return Vector2(clamped_x, clamped_y)


static func _HashCellSeed(p_seed: int, p_x: int, p_y: int) -> int:
	return hash([p_seed, p_x, p_y])


static func _SortByZThenY(p_a: DecorPlacement, p_b: DecorPlacement) -> bool:
	if p_a.z_index != p_b.z_index:
		return p_a.z_index < p_b.z_index
	return p_a.position.y < p_b.position.y
