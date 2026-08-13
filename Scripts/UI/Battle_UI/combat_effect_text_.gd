class_name CombatEffectText
extends Node2D

const MINIMUM_SPAWN_SCALE: float = 0.00001
const GROW_DURATION: float = 0.18
const SETTLE_DURATION: float = 0.15
const SHRINK_DURATION: float = 0.45

@export var label: Label
@export var animation_player: AnimationPlayer
@export var label_container: Node2D

var escalation_step: int = 0

var _position: Vector2
var _height: float
var _spread: float
var _base_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _base_font_size: int = 0
var _base_outline_size: int = 0
var _position_tween: Tween
var _scale_tween: Tween

func SetValue(
		p_text: String,
		p_position: Vector2,
		p_height: float,
		p_spread: float,
		p_color: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	label.text = p_text
	_base_color = p_color
	if(_base_font_size == 0):
		_base_font_size = label.get_theme_font_size(&"font_size")
		_base_outline_size = label.get_theme_constant(&"outline_size")
	label.add_theme_color_override("font_color", p_color)
	label.add_theme_font_size_override("font_size", _base_font_size)
	label.add_theme_constant_override("outline_size", _base_outline_size)
	_position = p_position
	_height = p_height
	_spread = p_spread

func ApplyEscalation(p_step: int) -> void:
	escalation_step = p_step
	var size_scale: float = BurstPacing.ScaleForStep(p_step)
	label.add_theme_color_override("font_color", BurstPacing.ColorForStep(_base_color, p_step))
	label.add_theme_font_size_override("font_size", int(round(_base_font_size * size_scale)))
	label.add_theme_constant_override("outline_size", maxi(1, int(round(_base_outline_size * size_scale))))

func Animate() -> void:
	animation_player.play("Damage_Number_Animation")

	if(_position_tween):
		_position_tween.kill()
	if(_scale_tween):
		_scale_tween.kill()

	var end_position = Vector2(randf_range(-_spread, _spread), -_height) + _position
	var tween_length = animation_player.get_animation("Damage_Number_Animation").length

	_position_tween = create_tween()
	_position_tween.tween_property(label_container, "position", end_position, tween_length).from(_position)

	var peak_scale: float = BurstPacing.OvershootForStep(escalation_step)
	var hold_duration: float = tween_length - GROW_DURATION - SETTLE_DURATION - SHRINK_DURATION

	_scale_tween = create_tween()
	_scale_tween.tween_property(label_container, "scale", Vector2.ONE * peak_scale, GROW_DURATION) \
			.from(Vector2.ONE * MINIMUM_SPAWN_SCALE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(label_container, "scale", Vector2.ONE, SETTLE_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_scale_tween.tween_interval(hold_duration)
	_scale_tween.tween_property(label_container, "scale", Vector2.ZERO, SHRINK_DURATION)

func remove() -> void:
	animation_player.stop()
	if(_position_tween):
		_position_tween.kill()
	if(_scale_tween):
		_scale_tween.kill()
	if(is_inside_tree()):
		get_parent().remove_child(self)
