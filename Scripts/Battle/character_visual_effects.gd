class_name CharacterVisualEffects extends Node2D

const PHASE_PULSE_SECONDS: float = 0.6
const PHASE_PULSE_GROWTH: float = 1.6
const PHASE_PULSE_START_ALPHA: float = 0.8
const TRANSLUCENT_ALPHA: float = 0.4

@export var _source_texture_rect: TextureRect
## Fills the whole silhouette behind the sprite, so it is hidden while the sprite is see-through.
@export var _silhouette_outline: TextureRect
@export var _echo_textures: Array[TextureRect]
@export var _phase_pulse: TextureRect
## Holds the one visuals scene a character's trait mounts through TraitVisuals.
@export var _trait_visuals_mount: Node2D

var _phase_pulse_base_scale: Vector2 = Vector2.ONE
var _phase_pulse_tween: Tween
var _art_scale: Vector2 = Vector2.ONE
var _trait_visuals: Node = null

func SetSpriteEchoes(p_count: int) -> void:
	for index in _echo_textures.size():
		if index < p_count:
			_echo_textures[index].texture = _source_texture_rect.texture
			_echo_textures[index].show()
		else:
			_echo_textures[index].hide()

func SetEchoScale(p_scale: Vector2) -> void:
	for echo in _echo_textures:
		echo.pivot_offset = _source_texture_rect.pivot_offset
		echo.scale = p_scale

func SetPhasePulseScale(p_scale: Vector2) -> void:
	_phase_pulse.pivot_offset = _source_texture_rect.pivot_offset
	_phase_pulse_base_scale = p_scale

func SetArtScale(p_scale: Vector2) -> void:
	_art_scale = p_scale

func PlayPhasePulse() -> void:
	if(_phase_pulse_tween):
		_phase_pulse_tween.kill()
	_phase_pulse.texture = _source_texture_rect.texture
	_phase_pulse.flip_h = _source_texture_rect.flip_h
	_phase_pulse.scale = _phase_pulse_base_scale
	_phase_pulse.modulate.a = PHASE_PULSE_START_ALPHA
	_phase_pulse.show()
	_phase_pulse_tween = create_tween()
	_phase_pulse_tween.set_parallel(true)
	_phase_pulse_tween.tween_property(_phase_pulse, "scale", _phase_pulse_base_scale * PHASE_PULSE_GROWTH,
			PHASE_PULSE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_phase_pulse_tween.tween_property(_phase_pulse, "modulate:a", 0.0, PHASE_PULSE_SECONDS)
	_phase_pulse_tween.chain().tween_callback(_phase_pulse.hide)

func SetTranslucent(p_translucent: bool) -> void:
	_source_texture_rect.self_modulate.a = TRANSLUCENT_ALPHA if p_translucent else 1.0
	_silhouette_outline.visible = not p_translucent

## The character's own visuals scene, instanced into the mount on the first call (once per
## battle view) and returned as is afterwards.
func TraitVisuals(p_scene: PackedScene) -> Node:
	if(null == _trait_visuals):
		_trait_visuals = p_scene.instantiate()
		_trait_visuals_mount.add_child(_trait_visuals)
	return _trait_visuals

## The global position of the Marker2D named p_name in the trait visuals, or p_fallback.
func MarkerPosition(p_name: StringName, p_fallback: Vector2) -> Vector2:
	var marker: Marker2D = (_trait_visuals.find_child(p_name, true, false) as Marker2D
			if null != _trait_visuals else null)
	return marker.global_position if null != marker else p_fallback

## A local point on the sprite box: p_fraction of its size plus p_offset, both in unscaled sprite
## pixels, read off the art scale alone so it holds still while the sprite breathes and reacts.
func SpritePoint(p_fraction: Vector2, p_offset: Vector2 = Vector2.ZERO) -> Vector2:
	return ScaledSpritePoint(_source_texture_rect.pivot_offset, _source_texture_rect.size, _art_scale,
			p_fraction, p_offset)

static func ScaledSpritePoint(
		p_pivot: Vector2, p_size: Vector2, p_art_scale: Vector2, p_fraction: Vector2, p_offset: Vector2) -> Vector2:
	return p_pivot + (p_size * p_fraction + p_offset - p_pivot) * p_art_scale
