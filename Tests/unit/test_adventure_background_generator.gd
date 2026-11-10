extends GutTest

var _canvas_size: Vector2 = Vector2(512, 512)
var _node_positions: Dictionary = {}

func before_each() -> void:
	_node_positions.clear()
	var node := NodeData.new()
	node.index = 0
	node.node_type = NodeData.Node_Type.FIGHT
	_node_positions[node] = Vector2(256, 256)


func _BuildLayer(p_density: float, p_threshold_min: float, p_threshold_max: float, p_node_avoidance_radius: float = 0.0) -> DecorLayerData:
	var layer := DecorLayerData.new()
	layer.textures = [PlaceholderTexture2D.new()]
	layer.density = p_density
	layer.noise_threshold_min = p_threshold_min
	layer.noise_threshold_max = p_threshold_max
	layer.node_avoidance_radius = p_node_avoidance_radius
	return layer


func _BuildVisualData(p_zones: Array[BiomeRegionData]) -> BiomeVisualData:
	var visual_data := BiomeVisualData.new()
	visual_data.detail_noise = FastNoiseLite.new()
	visual_data.detail_noise.frequency = 0.05
	visual_data.region_noise = FastNoiseLite.new()
	visual_data.region_noise.frequency = 0.01
	visual_data.regions = p_zones
	visual_data.coarse_cell_size = 256.0
	visual_data.fine_cell_size = 44.0
	return visual_data


func _BuildZone(p_name: String, p_weight: float, p_layer: DecorLayerData, p_density_multiplier: float = 1.0) -> BiomeRegionData:
	var zone := BiomeRegionData.new()
	zone.name = p_name
	zone.selection_weight = p_weight
	var entry := ZoneDecorEntry.new()
	entry.layer = p_layer
	entry.density_multiplier = p_density_multiplier
	zone.decor = [entry]
	return zone


func _BuildCluster(p_layer: DecorLayerData, p_inner_radius: float = 48.0, p_outer_radius: float = 96.0, p_sample_count: int = 12) -> NodePropCluster:
	var cluster := NodePropCluster.new()
	var entry := ZoneDecorEntry.new()
	entry.layer = p_layer
	cluster.decor = [entry]
	cluster.inner_radius = p_inner_radius
	cluster.outer_radius = p_outer_radius
	cluster.sample_count = p_sample_count
	return cluster


func test_determinism_same_seed_identical() -> void:
	var layer: DecorLayerData = _BuildLayer(0.6, 0.0, 1.0)
	var zone: BiomeRegionData = _BuildZone("Only", 1.0, layer)
	var visual_data: BiomeVisualData = _BuildVisualData([zone])

	var first: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 42)
	var second: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 42)

	assert_eq(first.size(), second.size(), "Same seed must produce the same placement count.")
	for i in first.size():
		assert_eq(first[i].position, second[i].position, "Same seed must produce identical positions.")


func test_different_seed_produces_different_result() -> void:
	var layer: DecorLayerData = _BuildLayer(0.6, 0.0, 1.0)
	var zone: BiomeRegionData = _BuildZone("Only", 1.0, layer)
	var visual_data: BiomeVisualData = _BuildVisualData([zone])

	var first: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 1)
	var second: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 2)

	var same: bool = first.size() == second.size()
	if same:
		for i in first.size():
			if first[i].position != second[i].position:
				same = false
				break
	assert_false(same, "Different seeds should not produce an identical placement layout.")


func test_forest_zone_denser_than_clearing_zone() -> void:
	var dense_layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var sparse_layer: DecorLayerData = _BuildLayer(0.0, 0.0, 1.0)
	var forest: BiomeRegionData = _BuildZone("Forest", 1.0, dense_layer)
	var clearing: BiomeRegionData = _BuildZone("Forest", 0.0, sparse_layer)

	var forest_only: BiomeVisualData = _BuildVisualData([forest])
	var clearing_only: BiomeVisualData = _BuildVisualData([clearing])

	var forest_placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(forest_only, _canvas_size, _node_positions, 7)
	var clearing_placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(clearing_only, _canvas_size, _node_positions, 7)

	assert_gt(forest_placements.size(), clearing_placements.size(), "A dense zone should yield more placements than a near-empty zone.")


func test_node_avoidance_radius_keeps_placements_clear_of_nodes() -> void:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0, 80.0)
	var zone: BiomeRegionData = _BuildZone("Only", 1.0, layer)
	var visual_data: BiomeVisualData = _BuildVisualData([zone])

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 99)

	var node_position: Vector2 = _node_positions.values()[0]
	var node_center: Vector2 = node_position + Vector2(40.0, 40.0)
	var node_rect := Rect2(node_center - Vector2(40.0, 40.0), Vector2(80.0, 80.0))
	for placement in placements:
		if placement.z_index == AdventureBackgroundGenerator.NODE_PROP_Z_INDEX:
			continue
		var texture_size: Vector2 = placement.texture.get_size()
		var half_width: float = texture_size.x * 0.5 * placement.scale
		var height: float = texture_size.y * placement.scale
		var decor_rect := Rect2(placement.position.x - half_width, placement.position.y - height, half_width * 2.0, height)
		decor_rect = decor_rect.grow(80.0)
		assert_false(decor_rect.intersects(node_rect), "Decor placements must respect node_avoidance_radius around nodes as a footprint gap.")


func test_decor_with_large_footprint_near_node_is_rejected() -> void:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0, 40.0)
	var big_texture := PlaceholderTexture2D.new()
	big_texture.size = Vector2(160, 384)
	layer.textures = [big_texture]
	layer.scale_min = 1.0
	layer.scale_max = 1.0
	var zone: BiomeRegionData = _BuildZone("Only", 1.0, layer)
	var visual_data: BiomeVisualData = _BuildVisualData([zone])

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 17)

	var node_position: Vector2 = _node_positions.values()[0]
	var node_center: Vector2 = node_position + Vector2(40.0, 40.0)
	var node_rect := Rect2(node_center - Vector2(40.0, 40.0), Vector2(80.0, 80.0))
	for placement in placements:
		if placement.z_index == AdventureBackgroundGenerator.NODE_PROP_Z_INDEX:
			continue
		var half_width: float = placement.texture.get_size().x * 0.5 * placement.scale
		var height: float = placement.texture.get_size().y * placement.scale
		var decor_rect := Rect2(placement.position.x - half_width, placement.position.y - height, half_width * 2.0, height)
		decor_rect = decor_rect.grow(40.0)
		assert_false(decor_rect.intersects(node_rect), "A large decor footprint must not overlap the node once node_avoidance_radius is applied as a gap.")


func test_region_coherence_neighbouring_cells_share_zone() -> void:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var zone_a: BiomeRegionData = _BuildZone("A", 1.0, layer)
	var zone_b: BiomeRegionData = _BuildZone("B", 1.0, layer)
	var visual_data: BiomeVisualData = _BuildVisualData([zone_a, zone_b])
	visual_data.region_noise.seed = 5

	var coarse_size: float = visual_data.coarse_cell_size
	var same_zone_count: int = 0
	var total_pairs: int = 0
	for coarse_y in range(20):
		for coarse_x in range(20):
			var current: int = _ZoneIndexAt(visual_data, coarse_x, coarse_y, coarse_size)
			var right: int = _ZoneIndexAt(visual_data, coarse_x + 1, coarse_y, coarse_size)
			total_pairs += 1
			if current == right:
				same_zone_count += 1

	var coherence_fraction: float = float(same_zone_count) / float(total_pairs)
	assert_gt(coherence_fraction, 0.5, "Low-frequency region noise should keep most neighbouring cells in the same zone.")


func test_node_cluster_props_ring_the_node() -> void:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var prop_texture := PlaceholderTexture2D.new()
	prop_texture.size = Vector2(16, 16)
	layer.textures = [prop_texture]
	layer.scale_min = 1.0
	layer.scale_max = 1.0
	var zone: BiomeRegionData = _BuildZone("Only", 1.0, _BuildLayer(0.0, 0.0, 1.0))
	var visual_data: BiomeVisualData = _BuildVisualData([zone])
	visual_data.node_props[NodeData.Node_Type.FIGHT] = _BuildCluster(layer, 48.0, 96.0, 20)

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 42)

	var node_position: Vector2 = _node_positions.values()[0]
	var node_center: Vector2 = node_position + Vector2(40.0, 40.0)
	var node_rect := Rect2(node_center - Vector2(40.0, 40.0), Vector2(80.0, 80.0))
	var found_cluster_prop: bool = false
	for placement in placements:
		if placement.z_index != AdventureBackgroundGenerator.NODE_PROP_Z_INDEX:
			continue
		found_cluster_prop = true
		assert_lte(placement.position.distance_to(node_center), 96.0 + 0.01, "Cluster prop must lie within the scatter ring's outer radius.")
		if placement.texture != null:
			var half_width: float = placement.texture.get_size().x * 0.5 * placement.scale
			var height: float = placement.texture.get_size().y * placement.scale
			var footprint := Rect2(placement.position.x - half_width, placement.position.y - height, half_width * 2.0, height)
			assert_false(footprint.intersects(node_rect), "Cluster prop footprint must not overlap the node icon rect.")
	assert_true(found_cluster_prop, "At least one cluster prop must be generated for a high-density layer.")


func test_node_prop_near_canvas_edge_stays_fully_on_screen() -> void:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var prop_texture := PlaceholderTexture2D.new()
	prop_texture.size = Vector2(56, 56)
	layer.textures = [prop_texture]
	layer.scale_min = 1.0
	layer.scale_max = 1.0
	var zone: BiomeRegionData = _BuildZone("Only", 1.0, _BuildLayer(0.0, 0.0, 1.0))
	var visual_data: BiomeVisualData = _BuildVisualData([zone])
	visual_data.node_props[NodeData.Node_Type.BOSS] = _BuildCluster(layer, 20.0, 60.0, 12)

	var boss_node := NodeData.new()
	boss_node.index = 1
	boss_node.node_type = NodeData.Node_Type.BOSS
	var node_positions: Dictionary = {boss_node: Vector2(_canvas_size.x - 5.0, 5.0)}

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, node_positions, 3)

	for placement in placements:
		if placement.z_index != AdventureBackgroundGenerator.NODE_PROP_Z_INDEX:
			continue
		if placement.texture == null:
			continue
		var rendered_size: Vector2 = placement.texture.get_size() * placement.scale
		var half_width: float = rendered_size.x * 0.5
		assert_gte(placement.position.x - half_width, -0.01, "Boss cluster prop must not bleed past the left edge.")
		assert_lte(placement.position.x + half_width, _canvas_size.x + 0.01, "Boss cluster prop must not bleed past the right edge.")
		assert_gte(placement.position.y - rendered_size.y, -0.01, "Boss cluster prop must not bleed past the top edge.")
		assert_lte(placement.position.y, _canvas_size.y + 0.01, "Boss cluster prop must not bleed past the bottom edge.")


func test_node_props_sort_above_all_decor() -> void:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	layer.z_index = 999
	var zone: BiomeRegionData = _BuildZone("Only", 1.0, layer)
	var visual_data: BiomeVisualData = _BuildVisualData([zone])
	var prop_layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	visual_data.node_props[NodeData.Node_Type.FIGHT] = _BuildCluster(prop_layer)

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 11)

	assert_eq(placements[-1].z_index, AdventureBackgroundGenerator.NODE_PROP_Z_INDEX, "Node props must sort after every decor layer, however high its z_index.")


func test_node_cluster_deterministic_per_seed() -> void:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var zone: BiomeRegionData = _BuildZone("Only", 0.0, _BuildLayer(0.0, 0.0, 1.0))
	var visual_data: BiomeVisualData = _BuildVisualData([zone])
	visual_data.node_props[NodeData.Node_Type.FIGHT] = _BuildCluster(layer)

	var first: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 99)
	var second: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 99)

	assert_eq(first.size(), second.size(), "Same seed must produce the same cluster placement count.")
	for i in first.size():
		assert_eq(first[i].position, second[i].position, "Same seed must produce identical cluster positions.")

	var node_a := NodeData.new()
	node_a.index = 10
	node_a.node_type = NodeData.Node_Type.FIGHT
	var node_b := NodeData.new()
	node_b.index = 11
	node_b.node_type = NodeData.Node_Type.FIGHT
	var two_nodes: Dictionary = {node_a: Vector2(100, 100), node_b: Vector2(400, 200)}

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, two_nodes, 99)
	var center_a: Vector2 = Vector2(100, 100) + Vector2(40.0, 40.0)
	var center_b: Vector2 = Vector2(400, 200) + Vector2(40.0, 40.0)
	var props_near_a: int = 0
	var props_near_b: int = 0
	for placement in placements:
		if placement.z_index != AdventureBackgroundGenerator.NODE_PROP_Z_INDEX:
			continue
		if placement.position.distance_to(center_a) < 100.0:
			props_near_a += 1
		if placement.position.distance_to(center_b) < 100.0:
			props_near_b += 1
	assert_gt(props_near_a, 0, "Node A must have cluster props near it.")
	assert_gt(props_near_b, 0, "Node B must have cluster props near it.")


func test_node_cluster_props_avoid_all_node_footprints() -> void:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var small_texture := PlaceholderTexture2D.new()
	small_texture.size = Vector2(10, 10)
	layer.textures = [small_texture]
	layer.scale_min = 1.0
	layer.scale_max = 1.0
	var zone: BiomeRegionData = _BuildZone("Only", 0.0, _BuildLayer(0.0, 0.0, 1.0))
	var visual_data: BiomeVisualData = _BuildVisualData([zone])
	visual_data.node_props[NodeData.Node_Type.FIGHT] = _BuildCluster(layer, 48.0, 96.0, 30)

	var node_a := NodeData.new()
	node_a.index = 0
	node_a.node_type = NodeData.Node_Type.FIGHT
	var node_b := NodeData.new()
	node_b.index = 1
	node_b.node_type = NodeData.Node_Type.FIGHT
	var node_positions: Dictionary = {node_a: Vector2(100, 100), node_b: Vector2(350, 350)}

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, node_positions, 77)

	var node_rects: Array[Rect2] = [
		Rect2(Vector2(100, 100) + Vector2(40.0, 40.0) - Vector2(40.0, 40.0), Vector2(80.0, 80.0)),
		Rect2(Vector2(350, 350) + Vector2(40.0, 40.0) - Vector2(40.0, 40.0), Vector2(80.0, 80.0)),
	]
	for placement in placements:
		if placement.z_index != AdventureBackgroundGenerator.NODE_PROP_Z_INDEX:
			continue
		if placement.texture == null:
			continue
		var half_width: float = placement.texture.get_size().x * 0.5 * placement.scale
		var height: float = placement.texture.get_size().y * placement.scale
		var footprint := Rect2(placement.position.x - half_width, placement.position.y - height, half_width * 2.0, height)
		for node_rect in node_rects:
			assert_false(footprint.intersects(node_rect), "Cluster prop must not overlap any node footprint.")


func _BuildClearerAndFillerVisualData(p_clears_other_decor: bool) -> BiomeVisualData:
	var clearer: DecorLayerData = _BuildLayer(0.15, 0.0, 1.0)
	var clearer_texture := PlaceholderTexture2D.new()
	clearer_texture.size = Vector2(120, 90)
	clearer.textures = [clearer_texture]
	clearer.z_index = -1
	clearer.clears_other_decor = p_clears_other_decor
	var filler: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var zone: BiomeRegionData = _BuildZone("Only", 1.0, clearer)
	var filler_entry := ZoneDecorEntry.new()
	filler_entry.layer = filler
	zone.decor.append(filler_entry)
	return _BuildVisualData([zone])


func _RenderedRect(p_placement: DecorPlacement) -> Rect2:
	var size: Vector2 = p_placement.texture.get_size() * p_placement.scale
	var top: float = p_placement.position.y - (size.y if p_placement.z_index >= 0 else size.y * 0.5)
	return Rect2(p_placement.position.x - size.x * 0.5, top, size.x, size.y)


func test_clearing_decor_removes_overlapping_decor() -> void:
	var visual_data: BiomeVisualData = _BuildClearerAndFillerVisualData(true)

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 5)

	var clearer_rects: Array[Rect2] = []
	for placement in placements:
		if placement.clears_other_decor:
			clearer_rects.append(_RenderedRect(placement))
	assert_gt(clearer_rects.size(), 0, "The scenario needs at least one clearing placement.")
	for placement in placements:
		if placement.clears_other_decor:
			continue
		for clearer_rect in clearer_rects:
			assert_false(_RenderedRect(placement).intersects(clearer_rect), "Non-clearing decor must not overlap clearing decor.")


func test_clearing_decor_does_not_overlap_other_clearing_decor() -> void:
	var clearer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var clearer_texture := PlaceholderTexture2D.new()
	clearer_texture.size = Vector2(120, 90)
	clearer.textures = [clearer_texture]
	clearer.clears_other_decor = true
	var visual_data: BiomeVisualData = _BuildVisualData([_BuildZone("Only", 1.0, clearer)])

	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 5)

	var clearers: Array[DecorPlacement] = placements.filter(
			func(p_placement: DecorPlacement) -> bool: return p_placement.clears_other_decor)
	assert_gt(clearers.size(), 1, "The scenario needs several clearing placements.")
	for first_index in clearers.size():
		for second_index in range(first_index + 1, clearers.size()):
			assert_false(_RenderedRect(clearers[first_index]).intersects(_RenderedRect(clearers[second_index])),
					"Clearing placements must not overlap each other.")


func test_clearing_flag_only_removes_overlapping_decor() -> void:
	var with_flag: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(
			_BuildClearerAndFillerVisualData(true), _canvas_size, _node_positions, 5)
	var without_flag: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(
			_BuildClearerAndFillerVisualData(false), _canvas_size, _node_positions, 5)

	assert_lt(with_flag.size(), without_flag.size(), "The flag should remove decor that overlapped a clearing placement.")
	assert_gt(with_flag.size(), 0, "Decor away from clearing placements should survive.")


func _ZoneIndexAt(p_visual_data: BiomeVisualData, p_coarse_x: int, p_coarse_y: int, p_coarse_size: float) -> int:
	var sample_position: Vector2 = Vector2(p_coarse_x, p_coarse_y) * p_coarse_size
	var noise_sample: float = p_visual_data.region_noise.get_noise_2d(sample_position.x, sample_position.y)
	noise_sample = clampf((noise_sample + 1.0) * 0.5, 0.0, 1.0)
	return 0 if noise_sample < 0.5 else 1


func _BuildStructuredVisuals(p_region: BiomeRegionData) -> BiomeVisualData:
	var visual_data: BiomeVisualData = _BuildVisualData([p_region])
	visual_data.structure_layout = StructureLayoutData.new()
	return visual_data


func _BuildLotLayout(p_rects: Array[Rect2], p_region: BiomeRegionData) -> StructureLayout:
	var layout := StructureLayout.new()
	for rect in p_rects:
		layout.lots.append(StructureLayout.Lot.new(rect, p_region))
	return layout


func _BuildLotLayer(p_mode: DecorLayerData.Placement_Mode, p_texture_size: Vector2 = Vector2(16, 16)) -> DecorLayerData:
	var layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	var texture := PlaceholderTexture2D.new()
	texture.size = p_texture_size
	layer.textures = [texture]
	layer.placement_mode = p_mode
	return layer


func _GenerateLots(p_layer: DecorLayerData, p_rects: Array[Rect2]) -> Array[DecorPlacement]:
	var region: BiomeRegionData = _BuildZone("Built", 1.0, p_layer)
	return AdventureBackgroundGenerator.Generate(
			_BuildStructuredVisuals(region), Vector2(1000, 1000), {}, 5, _BuildLotLayout(p_rects, region))


func test_edge_pieces_step_along_lot_sides() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE)
	layer.edge_spacing = 50.0
	var rect := Rect2(100, 100, 200, 150)
	var placements: Array[DecorPlacement] = _GenerateLots(layer, [rect])
	assert_eq(placements.size(), 4 * 2 + 3 * 2, "200 wide fits 4 pieces per side, 150 tall fits 3.")
	for placement in placements:
		var on_horizontal_side: bool = is_equal_approx(placement.position.y, rect.position.y) or is_equal_approx(
				placement.position.y, rect.end.y)
		var on_vertical_side: bool = is_equal_approx(placement.position.x, rect.position.x) or is_equal_approx(
				placement.position.x, rect.end.x)
		assert_true(on_horizontal_side or on_vertical_side, "Edge pieces sit on the lot's outline.")
		assert_eq(placement.rotation_degrees, 0.0, "Edge pieces are never rotated.")
		assert_false(placement.flip_h, "Edge pieces are never flipped.")


func test_edge_pieces_abut_at_their_spacing() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE)
	layer.edge_spacing = 50.0
	layer.edge_orientation = DecorLayerData.Edge_Orientation.HORIZONTAL
	var points: Array[Vector2] = AdventureBackgroundGenerator.EdgePoints(Rect2(0, 0, 230, 100), layer)
	var top_x: Array[float] = []
	for point in points:
		if is_zero_approx(point.y):
			top_x.append(point.x)
	assert_eq(top_x, [40.0, 90.0, 140.0, 190.0] as Array[float], "Pieces are centred on the side, one spacing apart.")


func test_edge_orientation_filters_sides() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE)
	layer.edge_spacing = 50.0
	layer.edge_orientation = DecorLayerData.Edge_Orientation.VERTICAL
	var rect := Rect2(0, 0, 200, 150)
	for point in AdventureBackgroundGenerator.EdgePoints(rect, layer):
		assert_true(is_zero_approx(point.x) or is_equal_approx(point.x, rect.end.x), "Vertical layers use side edges only.")
	var lowest_y: float = rect.end.y
	for point in AdventureBackgroundGenerator.EdgePoints(rect, layer):
		lowest_y = minf(lowest_y, point.y)
	assert_almost_eq(lowest_y, 50.0, 0.01, "Vertical pieces stack upward from their lower ends.")


func test_edge_inset_moves_pieces_inside_the_lot() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE)
	layer.edge_spacing = 50.0
	layer.edge_inset = 10.0
	var rect := Rect2(0, 0, 200, 200)
	for point in AdventureBackgroundGenerator.EdgePoints(rect, layer):
		assert_true(rect.grow(-9.99).has_point(point), "Inset pieces stay inside the lot.")


func test_corner_elements_sit_on_lot_corners() -> void:
	var rect := Rect2(100, 100, 200, 150)
	var placements: Array[DecorPlacement] = _GenerateLots(_BuildLotLayer(DecorLayerData.Placement_Mode.LOT_CORNER), [rect])
	var expected: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y),
			Vector2(rect.position.x, rect.end.y), rect.end]
	assert_eq(placements.size(), 4, "One element per corner.")
	for placement in placements:
		assert_has(expected, placement.position, "Corner elements sit exactly on corners.")


func test_fill_places_one_element_that_fits_each_lot() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_FILL, Vector2(100, 300))
	layer.scale_min = 0.5
	layer.scale_max = 2.0
	var rects: Array[Rect2] = [Rect2(0, 400, 180, 100), Rect2(400, 400, 40, 100)]
	var placements: Array[DecorPlacement] = _GenerateLots(layer, rects)
	assert_eq(placements.size(), 1, "The narrow lot cannot fit the texture at its minimum scale.")
	assert_lte(100.0 * placements[0].scale, 180.0, "The fill must fit the lot's width.")
	assert_eq(placements[0].position, Vector2(90, 500), "Props stand centred on the lot's bottom edge.")


func test_only_one_fill_claims_a_lot() -> void:
	var first: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_FILL)
	var second: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_FILL)
	var region: BiomeRegionData = _BuildZone("Built", 1.0, first)
	var second_entry := ZoneDecorEntry.new()
	second_entry.layer = second
	region.decor.append(second_entry)
	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(_BuildStructuredVisuals(region),
			Vector2(1000, 1000), {}, 5, _BuildLotLayout([Rect2(0, 0, 200, 200)], region))
	assert_eq(placements.size(), 1, "A lot holds at most one fill element.")


func test_fill_decal_fits_both_sides_and_centres() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_FILL, Vector2(100, 100))
	layer.z_index = -1
	layer.scale_min = 0.1
	layer.scale_max = 5.0
	var rect := Rect2(0, 0, 400, 120)
	var placements: Array[DecorPlacement] = _GenerateLots(layer, [rect])
	assert_lte(100.0 * placements[0].scale, 120.0 + 0.01, "Decals fit the lot's height too.")
	assert_eq(placements[0].position, rect.get_center(), "Decals sit centred in the lot.")


func test_lot_scatter_stays_inside_its_lot() -> void:
	var rect := Rect2(200, 300, 150, 120)
	var placements: Array[DecorPlacement] = _GenerateLots(_BuildLotLayer(DecorLayerData.Placement_Mode.SCATTER), [rect])
	assert_gt(placements.size(), 0, "Scatter should place inside the lot.")
	for placement in placements:
		assert_true(rect.has_point(placement.position), "Scatter never lands outside its lot.")


func test_noise_band_removes_lot_elements() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE)
	layer.edge_spacing = 10.0
	var full: int = _GenerateLots(layer, [Rect2(0, 0, 600, 600)]).size()
	layer.noise_threshold_min = 0.5
	var decayed: int = _GenerateLots(layer, [Rect2(0, 0, 600, 600)]).size()
	assert_gt(decayed, 0, "Some pieces survive decay.")
	assert_lt(decayed, full, "The noise band removes some pieces.")


func test_street_region_decorates_only_open_ground() -> void:
	var lot_layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_CORNER)
	var region: BiomeRegionData = _BuildZone("Built", 1.0, lot_layer)
	var visual_data: BiomeVisualData = _BuildStructuredVisuals(region)
	var street_layer: DecorLayerData = _BuildLayer(1.0, 0.0, 1.0)
	visual_data.structure_layout.street_region = _BuildZone("Street", 1.0, street_layer)
	var lot_rect := Rect2(100, 100, 300, 300)
	var layout: StructureLayout = _BuildLotLayout([lot_rect], region)
	layout.plazas.append(Rect2(600, 600, 100, 100))
	var placements: Array[DecorPlacement] = AdventureBackgroundGenerator.Generate(
			visual_data, Vector2(800, 800), {}, 5, layout)
	var street_count: int = 0
	for placement in placements:
		if placement.texture == street_layer.textures[0]:
			street_count += 1
			assert_false(lot_rect.has_point(placement.position), "Street decor stays off lots.")
			assert_false(layout.plazas[0].has_point(placement.position), "Street decor stays off plazas.")
	assert_gt(street_count, 0, "Open ground gets street decor.")


func test_organic_biomes_skip_lot_layers() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE)
	layer.edge_spacing = 10.0
	var visual_data: BiomeVisualData = _BuildVisualData([_BuildZone("Wild", 1.0, layer)])
	assert_eq(AdventureBackgroundGenerator.Generate(visual_data, _canvas_size, _node_positions, 5).size(), 0,
			"Lot layers place nothing without lots.")


func test_top_and_bottom_orientations_use_one_side_each() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE)
	layer.edge_spacing = 50.0
	var rect := Rect2(0, 0, 200, 150)
	layer.edge_orientation = DecorLayerData.Edge_Orientation.TOP
	for point in AdventureBackgroundGenerator.EdgePoints(rect, layer):
		assert_eq(point.y, rect.position.y, "Top layers use the top side only.")
	layer.edge_orientation = DecorLayerData.Edge_Orientation.BOTTOM
	for point in AdventureBackgroundGenerator.EdgePoints(rect, layer):
		assert_eq(point.y, rect.end.y, "Bottom layers use the bottom side only.")


func test_sides_of_whole_spacings_are_covered_corner_to_corner() -> void:
	var layer: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE)
	layer.edge_spacing = 64.0
	var rect := Rect2(128, 192, 256, 192)
	var top_x: Array[float] = []
	var left_y: Array[float] = []
	for point in AdventureBackgroundGenerator.EdgePoints(rect, layer):
		if is_equal_approx(point.y, rect.position.y):
			top_x.append(point.x)
		elif is_equal_approx(point.x, rect.position.x):
			left_y.append(point.y)
	assert_eq(top_x, [160.0, 224.0, 288.0, 352.0] as Array[float], "Top pieces span the side exactly.")
	assert_eq(left_y, [384.0, 320.0, 256.0] as Array[float], "Side pieces stack from the bottom corner to the top.")


func test_edge_overhang_measures_how_far_walls_rise_above_their_lot() -> void:
	var standing: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE, Vector2(128, 128))
	standing.scale_min = 0.5
	standing.scale_max = 0.5
	standing.edge_orientation = DecorLayerData.Edge_Orientation.TOP
	var side: DecorLayerData = _BuildLotLayer(DecorLayerData.Placement_Mode.LOT_EDGE, Vector2(48, 222))
	side.scale_min = 0.5
	side.scale_max = 0.5
	side.edge_spacing = 64.0
	side.edge_orientation = DecorLayerData.Edge_Orientation.VERTICAL
	var visual_data: BiomeVisualData = _BuildVisualData([_BuildZone("Top", 1.0, standing), _BuildZone("Side", 1.0, side)])
	assert_almost_eq(AdventureBackgroundGenerator.EdgeOverhang(visual_data), 64.0, 0.01,
			"A top wall rises its full height; a side wall rises its height past one step (47).")
	standing.edge_orientation = DecorLayerData.Edge_Orientation.BOTTOM
	assert_almost_eq(AdventureBackgroundGenerator.EdgeOverhang(visual_data), 47.0, 0.01,
			"Bottom walls rise into their own lot, not above it.")
