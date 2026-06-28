class_name AdventureBackground extends Control

## Renders the generated scenery for one adventure: a vertical gradient plus every
## DecorPlacement from AdventureBackgroundGenerator, drawn back-to-front. Pure view —
## holds the placement array and a gradient texture, no generation logic of its own.

var _visual_data: BiomeVisualData
var _node_positions: Dictionary = {}
var _generation_seed: int = -1
var _placements: Array[DecorPlacement] = []
var _gradient_texture: GradientTexture2D

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func Generate(p_visual_data: BiomeVisualData, p_node_positions: Dictionary, p_generation_seed: int) -> void:
	_visual_data = p_visual_data
	_node_positions = p_node_positions
	_generation_seed = p_generation_seed
	_Regenerate()

func _Regenerate() -> void:
	if _visual_data == null:
		return
	_gradient_texture = _BuildGradientTexture(_visual_data)
	_placements = AdventureBackgroundGenerator.Generate(_visual_data, size, _node_positions, _generation_seed)
	queue_redraw()

func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_RESIZED:
		_Regenerate()

func _BuildGradientTexture(p_visual_data: BiomeVisualData) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, p_visual_data.background_top_color)
	gradient.set_color(1, p_visual_data.background_bottom_color)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture

func _draw() -> void:
	if _gradient_texture != null:
		draw_texture_rect(_gradient_texture, Rect2(Vector2.ZERO, size), false)
	for placement in _placements:
		_DrawPlacement(placement)

func _DrawPlacement(p_placement: DecorPlacement) -> void:
	if p_placement.texture == null:
		return
	var texture_size: Vector2 = p_placement.texture.get_size()
	var pivot: Vector2 = Vector2(texture_size.x * 0.5, texture_size.y) if p_placement.z_index >= 0 else texture_size * 0.5
	var x_scale: float = -p_placement.scale if p_placement.flip_h else p_placement.scale

	draw_set_transform(p_placement.position, deg_to_rad(p_placement.rotation_degrees), Vector2(x_scale, p_placement.scale))
	draw_texture_rect(p_placement.texture, Rect2(-pivot, texture_size), false, p_placement.tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
