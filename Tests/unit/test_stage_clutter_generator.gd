extends GutTest

var _floor_rect: Rect2 = Rect2(Vector2(0, 430), Vector2(1280, 170))

func _BuildEntry(
		p_density: float = 1.0,
		p_avoidance_radius: float = 0.0,
		p_scale_min: float = 1.0,
		p_scale_max: float = 1.0) -> StageClutterEntry:
	var entry := StageClutterEntry.new()
	entry.textures = [PlaceholderTexture2D.new()]
	entry.density = p_density
	entry.character_avoidance_radius = p_avoidance_radius
	entry.scale_min = p_scale_min
	entry.scale_max = p_scale_max
	return entry


func test_no_placement_falls_inside_a_character_avoidance_radius() -> void:
	var avoidance_radius: float = 140.0
	var entries: Array[StageClutterEntry] = [_BuildEntry(1.0, avoidance_radius)]
	var characters: Array[Vector2] = [Vector2(300, 500), Vector2(900, 520)]

	var placements: Array[DecorPlacement] = StageClutterGenerator.Generate(
			entries, _floor_rect, characters, 99)

	assert_gt(placements.size(), 0, "the scatter produced something to check")
	for placement: DecorPlacement in placements:
		for character_position: Vector2 in characters:
			assert_gte(placement.position.distance_to(character_position), avoidance_radius,
					"clutter keeps clear of the character line")


func test_placements_stay_within_the_floor_rect() -> void:
	var entries: Array[StageClutterEntry] = [_BuildEntry()]
	var characters: Array[Vector2] = []

	var placements: Array[DecorPlacement] = StageClutterGenerator.Generate(
			entries, _floor_rect, characters, 5)

	assert_gt(placements.size(), 0)
	for placement: DecorPlacement in placements:
		assert_true(_floor_rect.has_point(placement.position),
				"placement %s sits inside the floor strip" % placement.position)


func test_same_seed_generates_the_same_placements() -> void:
	var entries: Array[StageClutterEntry] = [_BuildEntry(0.6, 0.0, 0.5, 2.0)]
	var characters: Array[Vector2] = [Vector2(640, 500)]

	var first: Array[DecorPlacement] = StageClutterGenerator.Generate(
			entries, _floor_rect, characters, 31)
	var second: Array[DecorPlacement] = StageClutterGenerator.Generate(
			entries, _floor_rect, characters, 31)

	assert_eq(first.size(), second.size())
	for index in first.size():
		assert_eq(first[index].position, second[index].position)
		assert_almost_eq(first[index].scale, second[index].scale, 0.0001)
		assert_almost_eq(first[index].rotation_degrees, second[index].rotation_degrees, 0.0001)
		assert_eq(first[index].flip_h, second[index].flip_h)


func test_different_seeds_diverge() -> void:
	var entries: Array[StageClutterEntry] = [_BuildEntry(0.6)]
	var characters: Array[Vector2] = []

	var first: Array[DecorPlacement] = StageClutterGenerator.Generate(
			entries, _floor_rect, characters, 1)
	var second: Array[DecorPlacement] = StageClutterGenerator.Generate(
			entries, _floor_rect, characters, 2)

	var first_positions: Array[Vector2] = []
	for placement: DecorPlacement in first:
		first_positions.append(placement.position)
	var second_positions: Array[Vector2] = []
	for placement: DecorPlacement in second:
		second_positions.append(placement.position)

	assert_ne(first_positions, second_positions)


func test_density_governs_how_much_is_scattered() -> void:
	var characters: Array[Vector2] = []
	var sparse: Array[StageClutterEntry] = [_BuildEntry(0.2)]
	var dense: Array[StageClutterEntry] = [_BuildEntry(1.0)]

	var sparse_count: int = StageClutterGenerator.Generate(
			sparse, _floor_rect, characters, 12).size()
	var dense_count: int = StageClutterGenerator.Generate(
			dense, _floor_rect, characters, 12).size()

	assert_lt(sparse_count, dense_count)
	assert_eq(StageClutterGenerator.Generate(
			[_BuildEntry(0.0)] as Array[StageClutterEntry], _floor_rect, characters, 12).size(), 0,
			"density zero scatters nothing")


func test_empty_input_returns_no_placements() -> void:
	var characters: Array[Vector2] = []
	var entries: Array[StageClutterEntry] = []

	assert_eq(StageClutterGenerator.Generate(entries, _floor_rect, characters, 3).size(), 0)
	assert_eq(StageClutterGenerator.Generate(
			[_BuildEntry()] as Array[StageClutterEntry],
			Rect2(Vector2.ZERO, Vector2.ZERO), characters, 3).size(), 0,
			"an empty floor rect scatters nothing")
