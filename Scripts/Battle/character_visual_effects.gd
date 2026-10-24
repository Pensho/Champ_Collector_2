class_name CharacterVisualEffects extends Node2D

const PHASE_PULSE_SECONDS: float = 0.6
const PHASE_PULSE_GROWTH: float = 1.6
const PHASE_PULSE_START_ALPHA: float = 0.8

@export var _source_texture_rect: TextureRect
@export var _echo_textures: Array[TextureRect]
@export var _phase_pulse: TextureRect

var _phase_pulse_base_scale: Vector2 = Vector2.ONE
var _phase_pulse_tween: Tween

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
