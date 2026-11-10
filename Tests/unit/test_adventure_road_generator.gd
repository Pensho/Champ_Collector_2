extends GutTest

func _BuildNoise(p_frequency: float = 0.05) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.frequency = p_frequency
	return noise


func test_determinism_same_seed_identical() -> void:
	var noise: FastNoiseLite = _BuildNoise()

	var first: PackedVector2Array = AdventureRoadGenerator.BuildRoadPoints(Vector2(0, 0), Vector2(300, 120), noise, 42)
	var second: PackedVector2Array = AdventureRoadGenerator.BuildRoadPoints(Vector2(0, 0), Vector2(300, 120), noise, 42)

	assert_eq(first.size(), second.size(), "Same seed must produce the same point count.")
	for i in first.size():
		assert_eq(first[i], second[i], "Same seed must produce identical points.")


func test_endpoints_match_input_positions() -> void:
	var noise: FastNoiseLite = _BuildNoise()
	var from: Vector2 = Vector2(10, 20)
	var to: Vector2 = Vector2(400, 260)

	var points: PackedVector2Array = AdventureRoadGenerator.BuildRoadPoints(from, to, noise, 7)

	assert_almost_eq(points[0], from, Vector2(0.01, 0.01), "First point must match the edge's start position.")
	assert_almost_eq(points[-1], to, Vector2(0.01, 0.01), "Last point must match the edge's end position.")


func test_winding_deviates_from_straight_line_within_sway_cap() -> void:
	var noise: FastNoiseLite = _BuildNoise()
	var from: Vector2 = Vector2(0, 0)
	var to: Vector2 = Vector2(500, 0)

	var points: PackedVector2Array = AdventureRoadGenerator.BuildRoadPoints(from, to, noise, 3)

	var max_deviation: float = 0.0
	for point in points:
		var deviation: float = absf(point.y)
		max_deviation = maxf(max_deviation, deviation)

	assert_gt(max_deviation, 0.0, "At least one interior point must deviate from the straight line.")
	assert_lte(max_deviation, AdventureRoadGenerator.SWAY_MAX + 0.01, "Deviation must stay within the sway cap.")


func test_degenerate_zero_length_edge_returns_two_points() -> void:
	var noise: FastNoiseLite = _BuildNoise()
	var point: Vector2 = Vector2(150, 90)

	var points: PackedVector2Array = AdventureRoadGenerator.BuildRoadPoints(point, point, noise, 5)

	assert_eq(points.size(), 2, "A degenerate (zero-length) edge must return a plain two-point line.")
	assert_eq(points[0], point, "Degenerate edge's first point must match the shared position.")
	assert_eq(points[1], point, "Degenerate edge's second point must match the shared position.")


const STREET_CANVAS_WIDTH: float = 1280.0


func test_street_roads_end_at_node_centers() -> void:
	var nodes: Array[NodeData] = _GenerateStreetNodes(4)
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, STREET_CANVAS_WIDTH, 0.0)
	var roads: Dictionary[Vector2i, PackedVector2Array] = AdventureRoadGenerator.BuildStreetRoads(
			nodes, positions, _BuildStreetSettings())
	for node in nodes:
		for next: NodeData in node.next_node:
			var road: PackedVector2Array = roads[Vector2i(node.index, next.index)]
			assert_eq(road[0], StructureLayoutGenerator.NodeCenter(positions[node]), "Road should start at its source.")
			assert_eq(road[-1], StructureLayoutGenerator.NodeCenter(positions[next]), "Road should end at its target.")


func test_street_roads_add_no_crossings_beyond_straight_lines() -> void:
	for vertical_jitter in [0.0, 20.0]:
		for adventure_seed in range(1, 31):
			var nodes: Array[NodeData] = _GenerateStreetNodes(adventure_seed)
			var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, STREET_CANVAS_WIDTH, vertical_jitter)
			var streets: Dictionary[Vector2i, PackedVector2Array] = AdventureRoadGenerator.BuildStreetRoads(
					nodes, positions, _BuildStreetSettings())
			var straight: Dictionary[Vector2i, PackedVector2Array] = {}
			for road_key in streets:
				straight[road_key] = PackedVector2Array([streets[road_key][0], streets[road_key][-1]])
			assert_lte(_CountCrossings(streets), _CountCrossings(straight),
					"Seed %d, jitter %d: streets crossed more than straight lines." % [adventure_seed, vertical_jitter])


func test_street_roads_never_pass_through_other_nodes() -> void:
	for adventure_seed in range(1, 21):
		var nodes: Array[NodeData] = _GenerateStreetNodes(adventure_seed)
		var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, STREET_CANVAS_WIDTH, 0.0)
		var roads: Dictionary[Vector2i, PackedVector2Array] = AdventureRoadGenerator.BuildStreetRoads(
				nodes, positions, _BuildStreetSettings())
		for road_key in roads:
			for node in nodes:
				if node.index == road_key.x or node.index == road_key.y:
					continue
				var node_rect := Rect2(positions[node], Vector2.ONE * AdventureNodePlacement.NODE_SIZE)
				assert_false(_PolylineEntersRect(roads[road_key], node_rect),
						"Seed %d: road %s passes through node %d." % [adventure_seed, road_key, node.index])


func test_street_lanes_keep_minimum_spacing() -> void:
	var settings: StructureLayoutData = _BuildStreetSettings()
	for adventure_seed in range(1, 21):
		var nodes: Array[NodeData] = _GenerateStreetNodes(adventure_seed)
		var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, STREET_CANVAS_WIDTH, 0.0)
		var roads: Dictionary[Vector2i, PackedVector2Array] = AdventureRoadGenerator.BuildStreetRoads(
				nodes, positions, settings)
		var keys: Array[Vector2i] = roads.keys()
		for first in keys.size():
			for second in range(first + 1, keys.size()):
				if _ShareNode(keys[first], keys[second]):
					continue
				for run_a in _HorizontalRuns(roads[keys[first]]):
					for run_b in _HorizontalRuns(roads[keys[second]]):
						if run_a.x <= run_b.y and run_b.x <= run_a.y:
							assert_gte(absf(run_a.z - run_b.z), settings.minimum_lane_spacing - 0.01,
									"Seed %d: lanes of %s and %s are too close." % [adventure_seed, keys[first], keys[second]])


func test_street_segments_are_axis_aligned_apart_from_chamfers() -> void:
	var settings: StructureLayoutData = _BuildStreetSettings()
	var nodes: Array[NodeData] = _GenerateStreetNodes(9)
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, STREET_CANVAS_WIDTH, 0.0)
	var roads: Dictionary[Vector2i, PackedVector2Array] = AdventureRoadGenerator.BuildStreetRoads(
			nodes, positions, settings)
	for road_key in roads:
		var road: PackedVector2Array = roads[road_key]
		for index in range(1, road.size()):
			var segment: Vector2 = road[index] - road[index - 1]
			var is_axis_aligned: bool = absf(segment.x) < 0.01 or absf(segment.y) < 0.01
			var is_chamfer: bool = (absf(absf(segment.x) - absf(segment.y)) < 0.01
					and absf(segment.x) <= settings.chamfer_size + 0.01)
			assert_true(is_axis_aligned or is_chamfer, "Road %s has a stray segment %s." % [road_key, segment])


func test_crowded_gap_falls_back_to_diagonals() -> void:
	var settings: StructureLayoutData = _BuildStreetSettings()
	settings.minimum_lane_spacing = 1000.0
	var nodes: Array[NodeData] = _BuildBranchedNodes()
	var positions: Dictionary = {nodes[0]: Vector2(100, 400), nodes[1]: Vector2(300, 200), nodes[2]: Vector2(500, 200)}
	var roads: Dictionary[Vector2i, PackedVector2Array] = AdventureRoadGenerator.BuildStreetRoads(
			nodes, positions, settings)
	var road: PackedVector2Array = roads[Vector2i(nodes[0].index, nodes[1].index)]
	var crossing: Vector2 = road[2] - road[1]
	assert_eq(road.size(), 4, "A fallback road is stub, diagonal, stub.")
	assert_false(is_zero_approx(crossing.x) or is_zero_approx(crossing.y), "The gap is crossed diagonally.")


func _BuildStreetSettings() -> StructureLayoutData:
	var settings := StructureLayoutData.new()
	settings.chamfer_size = 12.0
	settings.lane_spacing = 24.0
	settings.minimum_lane_spacing = 10.0
	settings.street_clearance = 8.0
	return settings


func _GenerateStreetNodes(p_seed: int) -> Array[NodeData]:
	var layout := AdventureLayout.new()
	layout.branching_paths = AdventureLayout.Mechanic_Frequency.HIGH
	var adventure := AdventureData.new()
	adventure.layout = layout
	seed(p_seed)
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(adventure)
	randomize()
	return nodes


## Two rows: one node splitting to two; placed to its right, both roads need separate lanes.
func _BuildBranchedNodes() -> Array[NodeData]:
	var nodes: Array[NodeData] = []
	for index in 3:
		var node := NodeData.new()
		node.index = index
		node.depth = 0 if index == 0 else 1
		nodes.append(node)
	for target_index in [1, 2]:
		nodes[0].next_node.append(nodes[target_index])
		nodes[target_index].previous_node.append(nodes[0])
	return nodes


func _CountCrossings(p_roads: Dictionary[Vector2i, PackedVector2Array]) -> int:
	var crossings: int = 0
	var keys: Array[Vector2i] = p_roads.keys()
	for first in keys.size():
		for second in range(first + 1, keys.size()):
			var road_a: PackedVector2Array = p_roads[keys[first]]
			var road_b: PackedVector2Array = p_roads[keys[second]]
			for index_a in range(1, road_a.size()):
				for index_b in range(1, road_b.size()):
					if _ProperlyIntersect(road_a[index_a - 1], road_a[index_a], road_b[index_b - 1], road_b[index_b]):
						crossings += 1
	return crossings


## True when the segments cross at a point strictly inside both; touching and overlapping
## along a shared stub do not count.
func _ProperlyIntersect(p_a: Vector2, p_b: Vector2, p_c: Vector2, p_d: Vector2) -> bool:
	var side_c: float = (p_b - p_a).cross(p_c - p_a)
	var side_d: float = (p_b - p_a).cross(p_d - p_a)
	var side_a: float = (p_d - p_c).cross(p_a - p_c)
	var side_b: float = (p_d - p_c).cross(p_b - p_c)
	const EPSILON: float = 0.001
	return side_c * side_d < -EPSILON and side_a * side_b < -EPSILON


func _PolylineEntersRect(p_points: PackedVector2Array, p_rect: Rect2) -> bool:
	var inner: Rect2 = p_rect.grow(-0.5)
	var corners: Array[Vector2] = [inner.position, Vector2(inner.end.x, inner.position.y), inner.end,
			Vector2(inner.position.x, inner.end.y)]
	for index in range(1, p_points.size()):
		if inner.has_point(p_points[index - 1]) or inner.has_point(p_points[index]):
			return true
		for corner_index in 4:
			if Geometry2D.segment_intersects_segment(p_points[index - 1], p_points[index],
					corners[corner_index], corners[(corner_index + 1) % 4]) != null:
				return true
	return false


## Each horizontal segment as Vector3(left x, right x, y).
func _HorizontalRuns(p_points: PackedVector2Array) -> Array[Vector3]:
	var runs: Array[Vector3] = []
	for index in range(1, p_points.size()):
		var start: Vector2 = p_points[index - 1]
		var end: Vector2 = p_points[index]
		if is_equal_approx(start.y, end.y) and not is_equal_approx(start.x, end.x):
			runs.append(Vector3(minf(start.x, end.x), maxf(start.x, end.x), start.y))
	return runs


func _ShareNode(p_first: Vector2i, p_second: Vector2i) -> bool:
	return (p_first.x == p_second.x or p_first.x == p_second.y
			or p_first.y == p_second.x or p_first.y == p_second.y)
