class_name GatheredLightShape extends Node2D

## A Gathered Light shape of equal wedge parts (the Hue-Eater's hexagon, a Gatherer's triangle),
## shown beside its owner and flown at the party by GatheredLightLaunch.

## Radians per second; positive turns clockwise.
@export var spin_speed: float = 0.125
## A gained part fades in while growing from this fraction of its size.
@export var appear_start_scale: float = 0.5
@export var appear_seconds: float = 0.8
@export var _shape: Node2D
@export var _slices: Array[Node2D]
## Grey motes gathering into each slice as it appears, in slice order.
@export var _slice_motes: Array[CPUParticles2D]
## Grey drops falling from each shown slice, in slice order.
@export var _slice_drips: Array[CPUParticles2D]

var _appear_tweens: Dictionary[Node2D, Tween] = {}

func _process(p_delta: float) -> void:
	_shape.rotation = wrapf(_shape.rotation + spin_speed * p_delta, 0.0, TAU)
	# Drops are born in their emitter's rotation, so the emitters stay upright as the shape spins.
	for drips in _slice_drips:
		drips.global_rotation = 0.0

func PartCount() -> int:
	return _slices.size()

## p_animate fades in and grows each slice that was hidden until now.
func SetSlices(p_count: int, p_animate: bool = false) -> void:
	visible = p_count > 0
	for index in _slices.size():
		var slice: Node2D = _slices[index]
		var shown: bool = index < p_count
		if shown and not slice.visible and p_animate:
			_Appear(slice)
			_slice_motes[index].restart()
		elif not shown:
			_StopAppearing(slice)
			_slice_motes[index].emitting = false
		slice.visible = shown
		_slice_drips[index].emitting = shown

func _Appear(p_slice: Node2D) -> void:
	_StopAppearing(p_slice)
	p_slice.modulate.a = 0.0
	p_slice.scale = Vector2.ONE * appear_start_scale
	var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(p_slice, "modulate:a", 1.0, appear_seconds)
	tween.tween_property(p_slice, "scale", Vector2.ONE, appear_seconds)
	_appear_tweens[p_slice] = tween

func _StopAppearing(p_slice: Node2D) -> void:
	if _appear_tweens.has(p_slice):
		_appear_tweens[p_slice].kill()
		_appear_tweens.erase(p_slice)
	p_slice.modulate.a = 1.0
	p_slice.scale = Vector2.ONE
