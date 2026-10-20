class_name AdventureGround extends TextureRect

## Bottom-most layer of the adventure map: the biome's vertical gradient fill, mottled by
## the biome's ground_material when it has one. Drawn below the roads (AdventureEdgeLayer)
## and decor (AdventureBackground) so both render on top of solid ground colour instead of
## the other way around.

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	stretch_mode = TextureRect.STRETCH_SCALE

func Generate(p_visual_data: BiomeVisualData, p_generation_seed: int) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, p_visual_data.background_top_color)
	gradient.set_color(1, p_visual_data.background_bottom_color)
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	texture = gradient_texture

	if p_visual_data.ground_material != null:
		# Duplicated so the per-adventure offset never writes into the shared biome resource.
		var ground_material: ShaderMaterial = p_visual_data.ground_material.duplicate()
		ground_material.set_shader_parameter("noise_offset", NoiseOffsetFromSeed(p_generation_seed))
		material = ground_material

## A deterministic offset into the tiling noise, each axis in [0, 1).
static func NoiseOffsetFromSeed(p_generation_seed: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_generation_seed
	return Vector2(rng.randf(), rng.randf())
