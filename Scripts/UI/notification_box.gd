class_name NotificationBox extends Control

signal finished

const RISE_HEIGHT: float = 40.0
const FADE_IN_DURATION: float = 0.2
const HOLD_DURATION: float = 1.0
const RISE_DURATION: float = 0.5

const KIND_COLORS: Dictionary = {
	Types.Notification_Kind.Info: Color(1.0, 1.0, 1.0, 1.0),
	Types.Notification_Kind.Failure: Color(0.9, 0.25, 0.25, 1.0),
}

@export var _label: Label
@export var _background: ColorRect

var _tween: Tween

func SetValue(p_text: String, p_kind: Types.Notification_Kind) -> void:
	_label.text = p_text
	_label.add_theme_color_override("font_color", KIND_COLORS[p_kind])

func GetSize() -> Vector2:
	return _background.get_rect().size

func Animate() -> void:
	if(_tween):
		_tween.kill()

	modulate.a = 0.0
	var start_position: Vector2 = position

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	_tween.tween_interval(HOLD_DURATION)
	_tween.tween_property(self, "position", start_position + Vector2(0.0, -RISE_HEIGHT), RISE_DURATION)
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, RISE_DURATION)
	_tween.set_parallel(false)
	_tween.tween_callback(func() -> void: finished.emit())
