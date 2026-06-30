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


func _ZoneIndexAt(p_visual_data: BiomeVisualData, p_coarse_x: int, p_coarse_y: int, p_coarse_size: float) -> int:
	var sample_position: Vector2 = Vector2(p_coarse_x, p_coarse_y) * p_coarse_size
	var noise_sample: float = p_visual_data.region_noise.get_noise_2d(sample_position.x, sample_position.y)
	noise_sample = clampf((noise_sample + 1.0) * 0.5, 0.0, 1.0)
	return 0 if noise_sample < 0.5 else 1
