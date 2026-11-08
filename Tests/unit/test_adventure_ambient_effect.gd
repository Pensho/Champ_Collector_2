extends GutTest

func _BuildEffect() -> AdventureAmbientEffect:
	var effect: AdventureAmbientEffect = autofree(AdventureAmbientEffect.new())
	effect.process_material = ParticleProcessMaterial.new()
	return effect


func test_amount_scales_with_height_within_bounds() -> void:
	var per_height: float = 6.0 / 720.0
	assert_eq(AdventureAmbientEffect.AmountForHeight(10.0, per_height, 6, 40), 6)
	assert_eq(AdventureAmbientEffect.AmountForHeight(2160.0, per_height, 6, 40), 18)
	assert_eq(AdventureAmbientEffect.AmountForHeight(100000.0, per_height, 6, 40), 40)


func test_amount_without_cap_is_unbounded() -> void:
	assert_eq(AdventureAmbientEffect.AmountForHeight(1000.0, 0.1, 1, 0), 100)


func test_emission_box_extends_past_left_edge_by_margin() -> void:
	var map_size := Vector2(800.0, 1000.0)
	var size: Vector2 = AdventureAmbientEffect.EmissionSize(map_size, 400.0)
	var center: Vector2 = AdventureAmbientEffect.EmissionCenter(map_size, 400.0)
	assert_eq(size, Vector2(1200.0, 1000.0))
	assert_eq(center.x - size.x * 0.5, -400.0, "left edge sits one margin off the map")
	assert_eq(center.x + size.x * 0.5, 800.0, "right edge sits on the map's edge")
	assert_eq(center.y, 500.0)


func test_visibility_rect_covers_emission_plus_particle_margin() -> void:
	var rect: Rect2 = AdventureAmbientEffect.VisibilityRect(Vector2(1200.0, 1000.0), 50.0)
	assert_eq(rect, Rect2(-650.0, -550.0, 1300.0, 1100.0))


func test_fit_to_map_sets_amount_position_and_emission() -> void:
	var effect: AdventureAmbientEffect = _BuildEffect()
	effect.amount_per_height = 0.01
	effect.FitToMap(Vector2(500.0, 2000.0))
	assert_eq(effect.amount, 20)
	assert_eq(effect.position, Vector2(250.0, 1000.0))
	var process := effect.process_material as ParticleProcessMaterial
	assert_eq(process.emission_shape_scale, Vector3(250.0, 1000.0, 0.5))


func test_fit_to_map_keeps_authored_amount_when_rate_unset() -> void:
	var effect: AdventureAmbientEffect = _BuildEffect()
	effect.amount = 7
	effect.FitToMap(Vector2(500.0, 2000.0))
	assert_eq(effect.amount, 7)


func test_fit_to_map_leaves_the_shared_scene_material_untouched() -> void:
	var effect: AdventureAmbientEffect = _BuildEffect()
	var shared_process := effect.process_material as ParticleProcessMaterial
	effect.FitToMap(Vector2(500.0, 2000.0))
	assert_ne(effect.process_material, shared_process)
	assert_eq(shared_process.emission_shape_scale, Vector3.ONE)
