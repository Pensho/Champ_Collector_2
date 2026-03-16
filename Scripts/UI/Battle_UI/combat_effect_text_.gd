class_name CombatEffectText
extends Node2D

@export var label: Label
@export var animation_player: AnimationPlayer
@export var label_container: Node2D

var _position: Vector2
var _height: float
var _spread: float

func SetValue(p_text: String, p_position: Vector2, p_height: float, p_spread: float, p_color: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	label.text = p_text
	label.add_theme_color_override("font_color", p_color)
	_position = p_position
	_height = p_height
	_spread = p_spread

func Animate() -> void:
	animation_player.play("Damage_Number_Animation")

	var tween = create_tween()
	var end_position = Vector2(randf_range(-_spread, _spread), -_height) + _position
	var tween_length = animation_player.get_animation("Damage_Number_Animation").length

	tween.tween_property(label_container, "position", end_position, tween_length).from(_position)

func remove() -> void:
	animation_player.stop()
	if(is_inside_tree()):
		get_parent().remove_child(self)
