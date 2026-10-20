extends GutTest

func _BuildVisualData(p_ground_material: ShaderMaterial) -> BiomeVisualData:
	var visual_data := BiomeVisualData.new()
	visual_data.background_top_color = Color.BLACK
	visual_data.background_bottom_color = Color.WHITE
	visual_data.ground_material = p_ground_material
	return visual_data


func test_noise_offset_is_deterministic_per_seed() -> void:
	assert_eq(AdventureGround.NoiseOffsetFromSeed(42), AdventureGround.NoiseOffsetFromSeed(42))


func test_noise_offset_differs_between_seeds() -> void:
	assert_ne(AdventureGround.NoiseOffsetFromSeed(1), AdventureGround.NoiseOffsetFromSeed(2))


func test_noise_offset_stays_within_one_texture_repeat() -> void:
	for generation_seed: int in [0, 1, 999, -7, 123456789]:
		var offset: Vector2 = AdventureGround.NoiseOffsetFromSeed(generation_seed)
		assert_between(offset.x, 0.0, 1.0)
		assert_between(offset.y, 0.0, 1.0)
		assert_lt(offset.x, 1.0)
		assert_lt(offset.y, 1.0)


func test_generate_without_ground_material_leaves_plain_gradient() -> void:
	var ground: AdventureGround = autofree(AdventureGround.new())
	ground.Generate(_BuildVisualData(null), 42)
	assert_null(ground.material)


func test_generate_offsets_a_copy_and_leaves_the_biome_material_untouched() -> void:
	var shared_material := ShaderMaterial.new()
	shared_material.shader = load("res://Assets/Champ_Collector/Shaders/adventure_ground.gdshader")
	var ground: AdventureGround = autofree(AdventureGround.new())
	ground.Generate(_BuildVisualData(shared_material), 42)

	assert_ne(ground.material, shared_material)
	assert_eq(ground.material.get_shader_parameter("noise_offset"), AdventureGround.NoiseOffsetFromSeed(42))
	assert_null(shared_material.get_shader_parameter("noise_offset"))
