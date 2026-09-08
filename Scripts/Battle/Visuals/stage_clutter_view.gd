@tool
class_name StageClutterView extends Control

## Draws one stage's floor clutter, back-to-front over the floor band's shader surface.
## The scatter rules are authored on this node per stage; the placements come from
## StageClutterGenerator. Character positions are the characters' feet, given in this
## control's local space, since that is the space the floor rect is scattered in. Runs in
## the editor so clutter is visible while a stage's bands are being laid out — there with
## no characters to keep clear of.

## This stage's scatter rules, authored in the inspector.
@export var entries: Array[StageClutterEntry]:
	set(value):
		entries = value
		_Regenerate()

var _character_positions: Array[Vector2] = []
var _generation_seed: int = -1
var _placements: Array[DecorPlacement] = []

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_Regenerate()

func Generate(p_character_positions: Array[Vector2], p_generation_seed: int) -> void:
	_character_positions = p_character_positions
	_generation_seed = p_generation_seed
	_Regenerate()

func _Regenerate() -> void:
	_placements = StageClutterGenerator.Generate(
			entries, Rect2(Vector2.ZERO, size), _character_positions, _generation_seed)
	queue_redraw()

func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_RESIZED:
		_Regenerate()

func _draw() -> void:
	for placement: DecorPlacement in _placements:
		_DrawPlacement(placement)

func _DrawPlacement(p_placement: DecorPlacement) -> void:
	if p_placement.texture == null:
		return
	var texture_size: Vector2 = p_placement.texture.get_size()
	var pivot: Vector2 = Vector2(texture_size.x * 0.5, texture_size.y)
	var x_scale: float = -p_placement.scale if p_placement.flip_h else p_placement.scale

	draw_set_transform(
			p_placement.position, deg_to_rad(p_placement.rotation_degrees),
			Vector2(x_scale, p_placement.scale))
	draw_texture_rect(p_placement.texture, Rect2(-pivot, texture_size), false, p_placement.tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
