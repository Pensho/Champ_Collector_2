class_name StructureLayoutGenerator extends RefCounted

## Pure static pipeline that turns the placed node graph into a StructureLayout,
## deterministic for a given seed. Biomes with a StructureLayoutData get street-routed
## roads, plazas, landmarks and lots; others get winding roads; no visual data gives
## straight lines.

## Random positions tried per landmark before it is given up for this map.
const LANDMARK_ATTEMPTS: int = 60


static func Build(
		p_visual_data: BiomeVisualData,
		p_nodes: Array[NodeData],
		p_node_positions: Dictionary,
		p_canvas_size: Vector2,
		p_seed: int) -> StructureLayout:
	var layout := StructureLayout.new()
	if p_visual_data != null and p_visual_data.structure_layout != null:
		var settings: StructureLayoutData = p_visual_data.structure_layout
		layout.roads = AdventureRoadGenerator.BuildStreetRoads(p_nodes, p_node_positions, settings)
		for node in p_nodes:
			layout.plazas.append(Rect2(p_node_positions[node], Vector2.ONE * AdventureNodePlacement.NODE_SIZE)
					.grow(settings.plaza_margin))
		layout.landmarks = _PlaceLandmarks(p_visual_data, layout, p_canvas_size, p_seed)
		layout.lots = _BuildLots(p_visual_data, layout, p_canvas_size, p_seed)
		return layout

	for node in p_nodes:
		for next: NodeData in node.next_node:
			var from_center: Vector2 = NodeCenter(p_node_positions[node])
			var to_center: Vector2 = NodeCenter(p_node_positions[next])
			var road_key := Vector2i(node.index, next.index)
			if p_visual_data == null:
				layout.roads[road_key] = PackedVector2Array([from_center, to_center])
			else:
				layout.roads[road_key] = AdventureRoadGenerator.BuildRoadPoints(
						from_center, to_center, p_visual_data.detail_noise, RoadSeed(p_seed, road_key))
	return layout


static func RoadSeed(p_seed: int, p_road_key: Vector2i) -> int:
	return hash([p_seed, p_road_key.x, p_road_key.y])


static func NodeCenter(p_node_position: Vector2) -> Vector2:
	var half_size: float = AdventureNodePlacement.NODE_SIZE * 0.5
	return p_node_position + Vector2(half_size, half_size)


## Splits the canvas into lots, carves plazas and road corridors out of them, and gives
## each surviving lot the region found at its centre.
static func _BuildLots(
		p_visual_data: BiomeVisualData,
		p_layout: StructureLayout,
		p_canvas_size: Vector2,
		p_seed: int) -> Array[StructureLayout.Lot]:
	var settings: StructureLayoutData = p_visual_data.structure_layout
	var lots: Array[StructureLayout.Lot] = []
	if settings.lot_size_max <= 0.0:
		return lots
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p_seed, "lots"])

	var pieces: Array[Rect2] = []
	for rect in SplitIntoLots(Rect2(Vector2.ZERO, p_canvas_size), settings, rng):
		pieces.append(_ShrinkRandomly(rect, settings.lot_jitter, rng))
	var holes: Array[Rect2] = p_layout.plazas + RoadCorridors(
			p_layout.roads, p_visual_data.road_width, settings.road_clearance)
	for landmark in p_layout.landmarks:
		holes.append(AdventureBackgroundGenerator.PlacementRect(landmark).grow(settings.street_width))
	# Walls rise above their lot's top side, so every hole reaches that far further down.
	var overhang: float = AdventureBackgroundGenerator.EdgeOverhang(p_visual_data)
	for hole in holes:
		var reach: Rect2 = hole.grow_side(SIDE_BOTTOM, overhang)
		var remaining: Array[Rect2] = []
		for piece in pieces:
			remaining.append_array(SubtractRect(piece, reach))
		pieces = remaining

	if p_visual_data.region_noise != null:
		p_visual_data.region_noise.seed = p_seed
	for piece in pieces:
		piece = SnapInward(piece, settings.lot_grid_size)
		if piece.size.x < settings.lot_size_min or piece.size.y < settings.lot_size_min:
			continue
		var region: BiomeRegionData = null
		if p_visual_data.region_noise != null and not p_visual_data.regions.is_empty():
			region = AdventureBackgroundGenerator.PickZoneAt(p_visual_data, piece.get_center())
		lots.append(StructureLayout.Lot.new(piece, region))
	return lots


## p_rect shrunk to the largest rect inside it whose sides lie on multiples of p_grid_size.
static func SnapInward(p_rect: Rect2, p_grid_size: float) -> Rect2:
	if p_grid_size <= 0.0:
		return p_rect
	var start := Vector2(ceilf(p_rect.position.x / p_grid_size), ceilf(p_rect.position.y / p_grid_size)) * p_grid_size
	var end := Vector2(floorf(p_rect.end.x / p_grid_size), floorf(p_rect.end.y / p_grid_size)) * p_grid_size
	return Rect2(start, end - start)


## Each landmark is rolled count_min..count_max times and tried at random positions whose
## rendered rect stays inside the canvas and clear of plazas, road corridors and earlier
## landmarks (kept street_width apart). A landmark with no room left is skipped.
static func _PlaceLandmarks(
		p_visual_data: BiomeVisualData,
		p_layout: StructureLayout,
		p_canvas_size: Vector2,
		p_seed: int) -> Array[DecorPlacement]:
	var settings: StructureLayoutData = p_visual_data.structure_layout
	var placed: Array[DecorPlacement] = []
	var blockers: Array[Rect2] = p_layout.plazas + RoadCorridors(
			p_layout.roads, p_visual_data.road_width, settings.road_clearance)
	var canvas := Rect2(Vector2.ZERO, p_canvas_size)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p_seed, "landmarks"])
	for landmark in settings.landmarks:
		if landmark == null or landmark.layer == null or landmark.layer.textures.is_empty():
			continue
		var layer: DecorLayerData = landmark.layer
		for _instance in rng.randi_range(landmark.count_min, maxi(landmark.count_min, landmark.count_max)):
			for _attempt in LANDMARK_ATTEMPTS:
				var placement := DecorPlacement.new()
				placement.texture = layer.textures[rng.randi_range(0, layer.textures.size() - 1)]
				placement.scale = rng.randf_range(layer.scale_min, layer.scale_max)
				placement.position = Vector2(rng.randf() * p_canvas_size.x, rng.randf() * p_canvas_size.y)
				placement.flip_h = layer.allow_horizontal_flip and rng.randf() < 0.5
				placement.tint = layer.tint
				placement.z_index = layer.z_index
				placement.clears_other_decor = layer.clears_other_decor
				var rect: Rect2 = AdventureBackgroundGenerator.PlacementRect(placement)
				if not canvas.encloses(rect) or _OverlapsAny(rect.grow(settings.street_width), blockers):
					continue
				placed.append(placement)
				blockers.append(rect)
				break
	return placed


static func _OverlapsAny(p_rect: Rect2, p_others: Array[Rect2]) -> bool:
	for other in p_others:
		if p_rect.intersects(other):
			return true
	return false


## Recursively halves p_area across its longer side, leaving street_width between the
## halves, until both sides are at most lot_size_max or a split would leave a half under
## lot_size_min. With a lot_grid_size, split lengths and streets are whole grid cells so
## the halves stay on the grid.
static func SplitIntoLots(p_area: Rect2, p_settings: StructureLayoutData, p_rng: RandomNumberGenerator) -> Array[Rect2]:
	var grid: float = p_settings.lot_grid_size
	var street: float = p_settings.street_width
	var shortest: float = p_settings.lot_size_min
	if grid > 0.0:
		street = ceilf(street / grid) * grid
		shortest = maxf(ceilf(shortest / grid) * grid, grid)
	var finished: Array[Rect2] = []
	var pending: Array[Rect2] = [p_area]
	while not pending.is_empty():
		var rect: Rect2 = pending.pop_back()
		var split_horizontally: bool = rect.size.x >= rect.size.y
		var length: float = rect.size.x if split_horizontally else rect.size.y
		var longest_allowed: float = length - street - shortest
		if maxf(rect.size.x, rect.size.y) <= p_settings.lot_size_max or longest_allowed < shortest:
			finished.append(rect)
			continue
		var first_length: float = p_rng.randf_range(shortest, longest_allowed)
		if grid > 0.0:
			first_length = clampf(floorf(first_length / grid) * grid, shortest, longest_allowed)
		var second_start: float = first_length + street
		if split_horizontally:
			pending.append(Rect2(rect.position, Vector2(first_length, rect.size.y)))
			pending.append(Rect2(rect.position + Vector2(second_start, 0.0),
					Vector2(rect.size.x - second_start, rect.size.y)))
		else:
			pending.append(Rect2(rect.position, Vector2(rect.size.x, first_length)))
			pending.append(Rect2(rect.position + Vector2(0.0, second_start),
					Vector2(rect.size.x, rect.size.y - second_start)))
	return finished


## p_rect minus p_hole, as up to four rectangles: full-width strips above and below the
## overlap, and the pieces left and right of it.
static func SubtractRect(p_rect: Rect2, p_hole: Rect2) -> Array[Rect2]:
	if not p_rect.intersects(p_hole):
		return [p_rect]
	var overlap: Rect2 = p_rect.intersection(p_hole)
	var candidates: Array[Rect2] = [
		Rect2(p_rect.position.x, p_rect.position.y, p_rect.size.x, overlap.position.y - p_rect.position.y),
		Rect2(p_rect.position.x, overlap.end.y, p_rect.size.x, p_rect.end.y - overlap.end.y),
		Rect2(p_rect.position.x, overlap.position.y, overlap.position.x - p_rect.position.x, overlap.size.y),
		Rect2(overlap.end.x, overlap.position.y, p_rect.end.x - overlap.end.x, overlap.size.y),
	]
	var pieces: Array[Rect2] = []
	for candidate in candidates:
		if candidate.size.x > 0.0 and candidate.size.y > 0.0:
			pieces.append(candidate)
	return pieces


## One rect per road segment: the segment's bounds grown by half the road plus clearance.
static func RoadCorridors(
		p_roads: Dictionary[Vector2i, PackedVector2Array], p_road_width: float, p_clearance: float) -> Array[Rect2]:
	var corridors: Array[Rect2] = []
	var margin: float = p_road_width * 0.5 + p_clearance
	for road_key in p_roads:
		var points: PackedVector2Array = p_roads[road_key]
		for index in range(1, points.size()):
			corridors.append(Rect2(points[index - 1], Vector2.ZERO).expand(points[index]).grow(margin))
	return corridors


static func _ShrinkRandomly(p_rect: Rect2, p_jitter: float, p_rng: RandomNumberGenerator) -> Rect2:
	if p_jitter <= 0.0:
		return p_rect
	return p_rect.grow_individual(
			-p_rng.randf_range(0.0, p_jitter), -p_rng.randf_range(0.0, p_jitter),
			-p_rng.randf_range(0.0, p_jitter), -p_rng.randf_range(0.0, p_jitter))
