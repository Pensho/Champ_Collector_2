class_name AdventureGroundGradient extends TextureRect

## Bottom-most layer of the adventure map: the biome's vertical gradient fill. Drawn below
## the roads (AdventureEdgeLayer) and decor (AdventureBackground) so both render on top of
## solid ground colour instead of the other way around.

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	stretch_mode = TextureRect.STRETCH_SCALE

func Generate(p_visual_data: BiomeVisualData) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, p_visual_data.background_top_color)
	gradient.set_color(1, p_visual_data.background_bottom_color)
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	texture = gradient_texture
