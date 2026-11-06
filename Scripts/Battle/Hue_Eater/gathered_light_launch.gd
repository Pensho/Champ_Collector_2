class_name GatheredLightLaunch extends SkillEffectScene

## A full Gathered Light shape flying from its owner's side to the party. The animation's length
## is the flight, so the held damage lands as the shape arrives.

@export var _shape: GatheredLightShape

var _flight: Tween


func Play(
		p_origin: Vector2,
		p_caster_position: Vector2,
		p_target_position: Vector2,
		p_variant: EffectVariant = null,
		p_scale: float = 1.0) -> void:
	super.Play(p_origin, p_caster_position, p_target_position, p_variant, p_scale)
	if(null != _flight):
		_flight.kill()
	_shape.position = Vector2.ZERO
	_shape.SetSlices(_shape.PartCount())
	var distance: float = p_origin.distance_to(p_target_position) / absf(scale.y)
	_flight = create_tween()
	_flight.tween_property(_shape, "position", Vector2(distance, 0.0), Length()) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
