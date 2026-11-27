class_name FortunesFavorPanel extends Node2D

## One shard of the Fortune's Favor reveal: a reward image clipped to the Content polygon,
## a vertex-colored glow ring around the frame line, and motes flowing out of the frame.

@export var _content: Polygon2D
@export var _glow: Polygon2D
@export var _frame: Sprite2D
@export var _motes: CPUParticles2D
@export var _reward_particles_holder: Node2D
@export var _glow_inner_width: float
@export var _glow_outer_width: float
@export var _mote_emission_point_count: int
@export var _slam_start_scale: float
@export var _resting_glow_alpha: float

var _rest_position: Vector2
var _tween: Tween
var _glow_tween: Tween
var _has_glow: bool = false
var _reward_particles: Node
var _has_landed: bool = false

func _ready() -> void:
	_rest_position = position
	_BuildGlowRing()
	_SetupMoteEmission()
	ResetHidden()

func SetEntry(p_texture: Texture2D, p_glow_color: Color, p_reward_particles: PackedScene) -> void:
	_content.texture = p_texture
	if(p_texture != null):
		_content.uv = FortunesFavorRevealLayout.CoverUvs(_content.polygon, p_texture.get_size())
	_has_glow = p_glow_color.a > 0.0
	_glow.modulate = p_glow_color
	_motes.color = p_glow_color

	if(_reward_particles != null):
		_reward_particles.queue_free()
		_reward_particles = null
	if(p_reward_particles != null):
		_reward_particles = p_reward_particles.instantiate()
		_reward_particles_holder.add_child(_reward_particles)

func ResetHidden() -> void:
	_KillTweens()
	position = _rest_position
	rotation = 0.0
	scale = Vector2.ONE
	modulate.a = 0.0
	_glow.self_modulate.a = 0.0
	_motes.emitting = false
	_reward_particles_holder.visible = false
	_has_landed = false

func SlamIn(p_duration: float) -> void:
	_KillTweens()
	scale = Vector2.ONE * _slam_start_scale
	_Land()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "modulate:a", 1.0, p_duration * 0.5)
	_tween.tween_property(self, "scale", Vector2.ONE, p_duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if(_has_glow):
		_motes.emitting = true
		_glow_tween = create_tween()
		_glow_tween.tween_property(_glow, "self_modulate:a", 1.0, p_duration)
		_glow_tween.tween_property(_glow, "self_modulate:a", _resting_glow_alpha, p_duration)

## Stops the motes and eases the glow down once the next panel takes the spotlight.
func Dim(p_duration: float) -> void:
	_motes.emitting = false
	if(_glow_tween != null):
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.tween_property(_glow, "self_modulate:a", 0.0, p_duration)

func SnapToRest() -> void:
	_KillTweens()
	position = _rest_position
	scale = Vector2.ONE
	modulate.a = 1.0
	_Land()

## Flies the panel off screen along p_direction; a zero direction flies it at the camera.
func BurstOut(p_direction: Vector2, p_distance: float, p_duration: float) -> void:
	_KillTweens()
	_motes.emitting = false
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if(p_direction == Vector2.ZERO):
		_tween.tween_property(self, "scale", Vector2.ONE * 3.0, p_duration)
		_tween.tween_property(self, "modulate:a", 0.0, p_duration)
		return
	_tween.tween_property(self, "position", _rest_position + p_direction * p_distance, p_duration)
	_tween.tween_property(self, "rotation", randf_range(-0.6, 0.6), p_duration)

func OutlineCenter() -> Vector2:
	return to_global(FortunesFavorRevealLayout.PolygonCentroid(_content.polygon))

## Shows the reward effect and fires its emitters once per landing.
func _Land() -> void:
	_reward_particles_holder.visible = true
	if(_has_landed or _reward_particles == null):
		return
	_has_landed = true
	for emitter in _reward_particles.find_children("*", "CPUParticles2D"):
		(emitter as CPUParticles2D).restart()

func _KillTweens() -> void:
	if(_tween != null):
		_tween.kill()
	if(_glow_tween != null):
		_glow_tween.kill()

func _BuildGlowRing() -> void:
	var outline: PackedVector2Array = _content.polygon
	var count: int = outline.size()
	var inner: PackedVector2Array = FortunesFavorRevealLayout.OffsetPolygon(outline, -_glow_inner_width)
	var outer: PackedVector2Array = FortunesFavorRevealLayout.OffsetPolygon(outline, _glow_outer_width)
	var points: PackedVector2Array = inner + outline + outer
	var colors: PackedColorArray = PackedColorArray()
	for ring_alpha in [0.0, 1.0, 0.0]:
		for index in count:
			colors.append(Color(1.0, 1.0, 1.0, ring_alpha))
	var quads: Array = []
	for ring in 2:
		for index in count:
			var next: int = (index + 1) % count
			quads.append(PackedInt32Array([
				ring * count + index, ring * count + next,
				(ring + 1) * count + next, (ring + 1) * count + index]))
	_glow.polygon = points
	_glow.vertex_colors = colors
	_glow.polygons = quads

func _SetupMoteEmission() -> void:
	var emission: Dictionary = FortunesFavorRevealLayout.EdgeEmission(_content.polygon, _mote_emission_point_count)
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_DIRECTED_POINTS
	_motes.emission_points = emission["points"]
	_motes.emission_normals = emission["normals"]
