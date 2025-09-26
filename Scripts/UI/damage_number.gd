class_name DamageNumber2D
extends Node2D

@onready var label: Label = $LabelContainer/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label_container: Node2D = $LabelContainer

func SetValueAndAnimate(p_text: String, p_position: Vector2, p_height: float, p_spread: float) -> void:
	label.text = p_text
	animation_player.play("Damage_Number_Animation")

	var tween = get_tree().create_tween()
	var end_position = Vector2(randf_range(-p_spread, p_spread), -p_height) + p_position
	var tween_length = animation_player.get_animation("Damage_Number_Animation").length

	tween.tween_property(label_container, "position", end_position, tween_length).from(p_position)

func remove() -> void:
	animation_player.stop()
	if(is_inside_tree()):
		get_parent().remove_child(self)
