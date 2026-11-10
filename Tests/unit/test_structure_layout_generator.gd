extends GutTest


func test_organic_biome_keeps_winding_roads() -> void:
	var visual_data := BiomeVisualData.new()
	visual_data.detail_noise = FastNoiseLite.new()
	var nodes: Array[NodeData] = _BuildPath()
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, 1280.0, 45.0)
	var layout: StructureLayout = StructureLayoutGenerator.Build(visual_data, nodes, positions, Vector2(1280.0, 1000.0), 42)
	var road_key := Vector2i(0, 1)
	var expected: PackedVector2Array = AdventureRoadGenerator.BuildRoadPoints(
			StructureLayoutGenerator.NodeCenter(positions[nodes[0]]),
			StructureLayoutGenerator.NodeCenter(positions[nodes[1]]),
			visual_data.detail_noise,
			StructureLayoutGenerator.RoadSeed(42, road_key))
	assert_eq(layout.roads[road_key], expected, "Organic biomes should draw the same winding road as before.")


func test_no_visual_data_draws_straight_roads() -> void:
	var nodes: Array[NodeData] = _BuildPath()
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, 1280.0, 45.0)
	var layout: StructureLayout = StructureLayoutGenerator.Build(null, nodes, positions, Vector2(1280.0, 1000.0), 42)
	assert_eq(layout.roads[Vector2i(0, 1)].size(), 2, "Without visual data a road is a straight line.")


func test_structured_biome_routes_streets() -> void:
	var visual_data := BiomeVisualData.new()
	visual_data.detail_noise = FastNoiseLite.new()
	visual_data.structure_layout = StructureLayoutData.new()
	var nodes: Array[NodeData] = _BuildPath()
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, 1280.0, 0.0)
	var layout: StructureLayout = StructureLayoutGenerator.Build(visual_data, nodes, positions, Vector2(1280.0, 1000.0), 42)
	var expected: Dictionary[Vector2i, PackedVector2Array] = AdventureRoadGenerator.BuildStreetRoads(
			nodes, positions, visual_data.structure_layout)
	assert_eq(layout.roads, expected, "A biome with structure layout data should get street roads.")


func test_every_edge_gets_a_road() -> void:
	var nodes: Array[NodeData] = _BuildPath()
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, 1280.0, 45.0)
	var layout: StructureLayout = StructureLayoutGenerator.Build(null, nodes, positions, Vector2(1280.0, 1000.0), 42)
	assert_eq(layout.roads.size(), nodes.size() - 1, "A path of n nodes has n - 1 roads.")


const LOT_CANVAS := Vector2(1280.0, 3000.0)


func test_lots_avoid_plazas_and_road_corridors() -> void:
	for adventure_seed in range(1, 11):
		var visual_data: BiomeVisualData = _BuildStructuredVisuals()
		var layout: StructureLayout = _BuildGeneratedLayout(visual_data, adventure_seed)
		var settings: StructureLayoutData = visual_data.structure_layout
		var margin: float = visual_data.road_width * 0.5 + settings.road_clearance
		for lot in layout.lots:
			for plaza in layout.plazas:
				assert_false(lot.rect.intersects(plaza), "Seed %d: a lot overlaps a plaza." % adventure_seed)
			for road_key in layout.roads:
				var road: PackedVector2Array = layout.roads[road_key]
				for index in range(1, road.size()):
					var corridor: Rect2 = Rect2(road[index - 1], Vector2.ZERO).expand(road[index]).grow(margin)
					assert_false(lot.rect.intersects(corridor), "Seed %d: a lot sits on road %s." % [adventure_seed, road_key])


func test_lots_stay_inside_canvas_without_overlapping() -> void:
	var visual_data: BiomeVisualData = _BuildStructuredVisuals()
	var layout: StructureLayout = _BuildGeneratedLayout(visual_data, 4)
	var canvas := Rect2(Vector2.ZERO, LOT_CANVAS)
	assert_gt(layout.lots.size(), 0, "A structured biome should produce lots.")
	for first in layout.lots.size():
		assert_true(canvas.encloses(layout.lots[first].rect), "Lots must stay inside the canvas.")
		for second in range(first + 1, layout.lots.size()):
			assert_false(layout.lots[first].rect.intersects(layout.lots[second].rect), "Lots must not overlap.")


func test_lots_respect_minimum_size_and_get_a_region() -> void:
	var visual_data: BiomeVisualData = _BuildStructuredVisuals()
	var layout: StructureLayout = _BuildGeneratedLayout(visual_data, 6)
	for lot in layout.lots:
		assert_gte(minf(lot.rect.size.x, lot.rect.size.y), visual_data.structure_layout.lot_size_min,
				"Lots under the minimum size should be dropped.")
		assert_not_null(lot.region, "Every lot should be given a region.")


func test_lots_are_deterministic_per_seed() -> void:
	var first: StructureLayout = _BuildGeneratedLayout(_BuildStructuredVisuals(), 8)
	var second: StructureLayout = _BuildGeneratedLayout(_BuildStructuredVisuals(), 8)
	assert_eq(first.lots.size(), second.lots.size(), "The same seed should give the same lots.")
	for index in first.lots.size():
		assert_eq(first.lots[index].rect, second.lots[index].rect, "The same seed should give the same lots.")


func test_split_respects_maximum_size_and_street_width() -> void:
	var settings := StructureLayoutData.new()
	settings.lot_size_min = 60.0
	settings.lot_size_max = 200.0
	settings.street_width = 20.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var lots: Array[Rect2] = StructureLayoutGenerator.SplitIntoLots(Rect2(0, 0, 1000, 700), settings, rng)
	for first in lots.size():
		assert_lte(maxf(lots[first].size.x, lots[first].size.y), settings.lot_size_max, "Lots should be split down.")
		for second in range(first + 1, lots.size()):
			assert_false(lots[first].grow(settings.street_width * 0.5 - 0.01).intersects(
					lots[second].grow(settings.street_width * 0.5 - 0.01)), "Split halves keep a street between them.")


func test_subtract_rect_leaves_the_area_outside_the_hole() -> void:
	var pieces: Array[Rect2] = StructureLayoutGenerator.SubtractRect(Rect2(0, 0, 100, 100), Rect2(40, 40, 20, 20))
	var area: float = 0.0
	for piece in pieces:
		assert_false(piece.intersects(Rect2(40, 40, 20, 20)), "No piece may overlap the hole.")
		area += piece.get_area()
	assert_almost_eq(area, 100.0 * 100.0 - 20.0 * 20.0, 0.01, "Pieces should cover everything but the hole.")


func test_organic_biome_has_no_lots() -> void:
	var visual_data := BiomeVisualData.new()
	visual_data.detail_noise = FastNoiseLite.new()
	var nodes: Array[NodeData] = _BuildPath()
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, 1280.0, 45.0)
	var layout: StructureLayout = StructureLayoutGenerator.Build(visual_data, nodes, positions, LOT_CANVAS, 42)
	assert_true(layout.lots.is_empty() and layout.plazas.is_empty(), "Organic biomes have no lots or plazas.")


func test_landmarks_place_within_count_and_clear_of_everything() -> void:
	for adventure_seed in range(1, 11):
		var visual_data: BiomeVisualData = _BuildStructuredVisuals()
		visual_data.structure_layout.landmarks = [_BuildLandmark(Vector2(300, 260), 2, 3)]
		var layout: StructureLayout = _BuildGeneratedLayout(visual_data, adventure_seed)
		assert_lte(layout.landmarks.size(), 3, "Seed %d: no more landmarks than count_max." % adventure_seed)
		var corridors: Array[Rect2] = StructureLayoutGenerator.RoadCorridors(
				layout.roads, visual_data.road_width, visual_data.structure_layout.road_clearance)
		var rects: Array[Rect2] = []
		for landmark in layout.landmarks:
			var rect: Rect2 = AdventureBackgroundGenerator.PlacementRect(landmark)
			assert_true(Rect2(Vector2.ZERO, LOT_CANVAS).encloses(rect), "Landmarks stay on the canvas.")
			for blocker in layout.plazas + corridors + rects:
				assert_false(rect.intersects(blocker), "Seed %d: a landmark overlaps a plaza, road or landmark." % adventure_seed)
			for lot in layout.lots:
				assert_false(rect.intersects(lot.rect), "Seed %d: a lot overlaps a landmark." % adventure_seed)
			rects.append(rect)


func test_landmarks_reach_their_minimum_count_on_open_ground() -> void:
	var visual_data: BiomeVisualData = _BuildStructuredVisuals()
	visual_data.structure_layout.landmarks = [_BuildLandmark(Vector2(200, 200), 2, 2)]
	var layout: StructureLayout = StructureLayoutGenerator.Build(visual_data, [] as Array[NodeData], {}, LOT_CANVAS, 3)
	assert_eq(layout.landmarks.size(), 2, "An empty map has room for every landmark.")


func test_landmarks_are_deterministic_per_seed() -> void:
	var visual_data: BiomeVisualData = _BuildStructuredVisuals()
	visual_data.structure_layout.landmarks = [_BuildLandmark(Vector2(300, 260), 1, 3)]
	var first: StructureLayout = _BuildGeneratedLayout(visual_data, 5)
	var second: StructureLayout = _BuildGeneratedLayout(visual_data, 5)
	assert_eq(first.landmarks.size(), second.landmarks.size(), "Same seed, same landmark count.")
	for index in first.landmarks.size():
		assert_eq(first.landmarks[index].position, second.landmarks[index].position, "Same seed, same positions.")


func test_grid_split_keeps_lots_on_the_grid() -> void:
	var settings := StructureLayoutData.new()
	settings.lot_size_min = 64.0
	settings.lot_size_max = 256.0
	settings.street_width = 24.0
	settings.lot_grid_size = 64.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for lot in StructureLayoutGenerator.SplitIntoLots(Rect2(0, 0, 1280, 1280), settings, rng):
		for value in [lot.position.x, lot.position.y, lot.end.x, lot.end.y]:
			assert_true(is_zero_approx(fmod(value, 64.0)), "Split lots lie on the grid, so snapping costs nothing.")


func test_snap_inward_aligns_sides_to_the_grid() -> void:
	var snapped: Rect2 = StructureLayoutGenerator.SnapInward(Rect2(10, 70, 250, 140), 64.0)
	assert_eq(snapped, Rect2(64, 128, 192, 64), "Sides move inward onto multiples of the grid.")
	assert_eq(StructureLayoutGenerator.SnapInward(Rect2(10, 70, 250, 140), 0.0), Rect2(10, 70, 250, 140),
			"A grid of 0 leaves the rect alone.")


func test_lots_leave_room_for_walls_rising_above_them() -> void:
	var visual_data: BiomeVisualData = _BuildStructuredVisuals()
	var wall := DecorLayerData.new()
	var texture := PlaceholderTexture2D.new()
	texture.size = Vector2(64, 90)
	wall.textures = [texture]
	wall.placement_mode = DecorLayerData.Placement_Mode.LOT_EDGE
	wall.edge_orientation = DecorLayerData.Edge_Orientation.TOP
	var entry := ZoneDecorEntry.new()
	entry.layer = wall
	visual_data.regions[0].decor = [entry]
	visual_data.structure_layout.lot_grid_size = 32.0
	for adventure_seed in range(1, 6):
		var layout: StructureLayout = _BuildGeneratedLayout(visual_data, adventure_seed)
		var corridors: Array[Rect2] = StructureLayoutGenerator.RoadCorridors(
				layout.roads, visual_data.road_width, visual_data.structure_layout.road_clearance)
		for lot in layout.lots:
			var wall_reach: Rect2 = lot.rect.grow_side(SIDE_TOP, 90.0)
			for blocker in layout.plazas + corridors:
				assert_false(wall_reach.intersects(blocker),
						"Seed %d: a wall above a lot would cover a road or plaza." % adventure_seed)
			assert_true(is_zero_approx(fmod(lot.rect.position.x, 32.0)) and is_zero_approx(fmod(lot.rect.end.y, 32.0)),
					"Lots sit on the grid.")


func _BuildLandmark(p_size: Vector2, p_count_min: int, p_count_max: int) -> LandmarkData:
	var texture := PlaceholderTexture2D.new()
	texture.size = p_size
	var layer := DecorLayerData.new()
	layer.textures = [texture]
	var landmark := LandmarkData.new()
	landmark.layer = layer
	landmark.count_min = p_count_min
	landmark.count_max = p_count_max
	return landmark


func _BuildStructuredVisuals() -> BiomeVisualData:
	var settings := StructureLayoutData.new()
	settings.lane_spacing = 24.0
	settings.minimum_lane_spacing = 10.0
	settings.street_clearance = 8.0
	settings.lot_size_min = 48.0
	settings.lot_size_max = 220.0
	settings.street_width = 20.0
	settings.lot_jitter = 10.0
	settings.plaza_margin = 20.0
	settings.road_clearance = 6.0
	var region := BiomeRegionData.new()
	region.name = "Built"
	var visual_data := BiomeVisualData.new()
	visual_data.detail_noise = FastNoiseLite.new()
	visual_data.region_noise = FastNoiseLite.new()
	visual_data.regions = [region]
	visual_data.road_width = 16.0
	visual_data.structure_layout = settings
	return visual_data


func _BuildGeneratedLayout(p_visual_data: BiomeVisualData, p_seed: int) -> StructureLayout:
	var adventure_layout := AdventureLayout.new()
	adventure_layout.MIN_DEPTH = 12
	adventure_layout.MAX_DEPTH = 14
	adventure_layout.branching_paths = AdventureLayout.Mechanic_Frequency.MEDIUM
	var adventure := AdventureData.new()
	adventure.layout = adventure_layout
	seed(p_seed)
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(adventure)
	randomize()
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, LOT_CANVAS.x, 0.0)
	return StructureLayoutGenerator.Build(p_visual_data, nodes, positions, LOT_CANVAS, p_seed)


func _BuildPath() -> Array[NodeData]:
	var nodes: Array[NodeData] = []
	for index in 4:
		var node := NodeData.new()
		node.index = index
		node.depth = index
		if index > 0:
			nodes[-1].next_node.append(node)
			node.previous_node.append(nodes[-1])
		nodes.append(node)
	return nodes
