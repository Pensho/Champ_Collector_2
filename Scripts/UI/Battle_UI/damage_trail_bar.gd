class_name DamageTrailBar extends ProgressBar

const HOLD_SECONDS: float = 0.8
const DRAIN_SECONDS: float = 0.3

var _tween: Tween

func Follow(p_current_health: float) -> void:
	if(_tween):
		_tween.kill()
	if(p_current_health >= value):
		value = p_current_health
		return
	_tween = create_tween()
	_tween.tween_interval(HOLD_SECONDS)
	_tween.tween_property(self, "value", p_current_health, DRAIN_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func SnapTo(p_current_health: float) -> void:
	if(_tween):
		_tween.kill()
	value = p_current_health
