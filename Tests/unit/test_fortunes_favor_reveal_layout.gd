extends GutTest

const PANEL_COUNT: int = 9
const NEUTRAL: Color = Color(1.0, 0.9, 0.6)


func _silver() -> Dictionary:
	return {"type": RecruitmentManager.RewardType.SILVER, "champion": null, "amount": 20}


func _supplies() -> Dictionary:
	return {"type": RecruitmentManager.RewardType.SUPPLIES, "champion": null, "amount": 10}


func _champion(p_rarity: Types.Rarity = Types.Rarity.Rare) -> Dictionary:
	var preset: CharacterPreset = CharacterPreset.new()
	preset._rarity = p_rarity
	return {"type": RecruitmentManager.RewardType.CHAMPION, "champion": preset, "amount": 1}


func _rewards(p_count: int, p_with_champion: bool) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for index in p_count:
		rewards.append(_silver() if index % 2 == 0 else _supplies())
	if(p_with_champion):
		rewards[p_count / 2] = _champion()
	return rewards


func _count_fillers(p_panels: Array[Dictionary]) -> int:
	var fillers: int = 0
	for entry in p_panels:
		if(entry.is_empty()):
			fillers += 1
	return fillers


func test_every_tier_fills_all_panels_with_fillers_for_the_remainder() -> void:
	for reward_count in [5, 7, 9]:
		var panels: Array[Dictionary] = FortunesFavorRevealLayout.AssignRewardsToPanels(
				_rewards(reward_count, false), PANEL_COUNT)
		assert_eq(panels.size(), PANEL_COUNT, "Always nine panels")
		assert_eq(_count_fillers(panels), PANEL_COUNT - reward_count, "Fillers pad the rewards to nine")


func test_champion_is_always_the_center_panel_and_never_an_outer_one() -> void:
	for attempt in 20:
		var panels: Array[Dictionary] = FortunesFavorRevealLayout.AssignRewardsToPanels(
				_rewards(5, true), PANEL_COUNT)
		assert_true(FortunesFavorRevealLayout.IsChampion(panels[PANEL_COUNT - 1]), "Champion lands last")
		for index in PANEL_COUNT - 1:
			assert_false(FortunesFavorRevealLayout.IsChampion(panels[index]), "No champion on outer panels")


func test_center_holds_a_real_reward_without_a_champion() -> void:
	for attempt in 20:
		var panels: Array[Dictionary] = FortunesFavorRevealLayout.AssignRewardsToPanels(
				_rewards(5, false), PANEL_COUNT)
		assert_false(panels[PANEL_COUNT - 1].is_empty(), "Center panel is never a filler")


func test_glow_color_follows_reward_kind() -> void:
	assert_eq(FortunesFavorRevealLayout.GlowColor(_champion(Types.Rarity.Epic), NEUTRAL),
			RarityColors.TEXT[Types.Rarity.Epic], "Champion glows in its rarity color")
	assert_eq(FortunesFavorRevealLayout.GlowColor(_silver(), NEUTRAL), NEUTRAL, "Silver glows neutral")
	assert_eq(FortunesFavorRevealLayout.GlowColor(_supplies(), NEUTRAL), NEUTRAL, "Supplies glow neutral")
	assert_eq(FortunesFavorRevealLayout.GlowColor({}, NEUTRAL).a, 0.0, "Fillers do not glow")


func test_centroid_of_a_triangle() -> void:
	var triangle: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(6, 0), Vector2(0, 3)])
	assert_almost_eq(FortunesFavorRevealLayout.PolygonCentroid(triangle), Vector2(2, 1), Vector2(0.001, 0.001))


func test_cover_uvs_stay_inside_the_texture_for_wide_tall_and_lopsided_shapes() -> void:
	var shapes: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(0, 0), Vector2(700, 0), Vector2(700, 200), Vector2(0, 200)]),
		PackedVector2Array([Vector2(0, 0), Vector2(150, 0), Vector2(150, 600), Vector2(0, 600)]),
		PackedVector2Array([Vector2(0, 0), Vector2(500, 0), Vector2(0, 400)]),
	]
	var texture_size: Vector2 = Vector2(512, 512)
	for shape in shapes:
		var uvs: PackedVector2Array = FortunesFavorRevealLayout.CoverUvs(shape, texture_size)
		for uv in uvs:
			assert_between(uv.x, -0.001, texture_size.x + 0.001, "uv x within texture")
			assert_between(uv.y, -0.001, texture_size.y + 0.001, "uv y within texture")


func test_cover_scale_reaches_the_farthest_bound_from_the_focus() -> void:
	var bounds: Rect2 = Rect2(0, 0, 400, 100)
	var scale: float = FortunesFavorRevealLayout.CoverScale(Vector2(100, 100), bounds, Vector2(100, 50))
	assert_almost_eq(scale, 6.0, 0.001, "Focus 100 from the left edge, 300 from the right: half-width 300")


func test_burst_direction_points_away_from_screen_center() -> void:
	var center: Vector2 = Vector2(640, 360)
	var direction: Vector2 = FortunesFavorRevealLayout.BurstDirection(Vector2(100, 100), center)
	assert_lt(direction.x, 0.0, "Left panel flies left")
	assert_lt(direction.y, 0.0, "Upper panel flies up")
	assert_almost_eq(direction.length(), 1.0, 0.001, "Unit vector")
	assert_eq(FortunesFavorRevealLayout.BurstDirection(center, center), Vector2.ZERO, "Centered panel has no direction")


func test_offset_polygon_moves_square_edges_by_the_distance() -> void:
	var square: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var grown: PackedVector2Array = FortunesFavorRevealLayout.OffsetPolygon(square, 2.0)
	assert_almost_eq(grown[0], Vector2(-2, -2), Vector2(0.001, 0.001), "Corner moves out diagonally")
	assert_almost_eq(grown[2], Vector2(12, 12), Vector2(0.001, 0.001), "Opposite corner too")
	var shrunk: PackedVector2Array = FortunesFavorRevealLayout.OffsetPolygon(square, -2.0)
	assert_almost_eq(shrunk[0], Vector2(2, 2), Vector2(0.001, 0.001), "Negative distance shrinks")


func test_edge_emission_samples_lie_on_the_outline_with_outward_normals() -> void:
	var square: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var emission: Dictionary = FortunesFavorRevealLayout.EdgeEmission(square, 8)
	var points: PackedVector2Array = emission["points"]
	var normals: PackedVector2Array = emission["normals"]
	assert_eq(points.size(), 8, "One point per requested sample")
	for index in points.size():
		var point: Vector2 = points[index]
		var on_outline: bool = is_zero_approx(point.x) or is_equal_approx(point.x, 10.0) \
				or is_zero_approx(point.y) or is_equal_approx(point.y, 10.0)
		assert_true(on_outline, "Sample on the square's outline")
		assert_gt(normals[index].dot(point - Vector2(5, 5)), 0.0, "Normal points away from the center")
