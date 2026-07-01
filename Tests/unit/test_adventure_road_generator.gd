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
