class_name ReagentPouch extends Control

const SLIDE_DURATION: float = 0.25

@export var _pouch_button: Button
@export var _reagent_list: Control
@export var _reagent_buttons: Array[ReagentButton]
@export var _backdrop: TextureRect

var _is_open: bool = false
var _rest_positions: Array[Vector2] = []
var _slide_tween: Tween

func _ready() -> void:
	for button in _reagent_buttons:
		_rest_positions.append(button.position)

func IsOpen() -> bool:
	return _is_open

func IsSliding() -> bool:
	return null != _slide_tween and _slide_tween.is_running()

func Toggle() -> void:
	if(_is_open):
		Close()
	else:
		Open()

func Open() -> void:
	_is_open = true
	_reagent_list.show()
	_backdrop.show()
	_SlideTo(_rest_positions, 1.0, _on_open_finished)

func Close() -> void:
	_is_open = false
	_SlideTo(_PouchPositions(), 0.0, _on_close_finished)

# Collapses without animating, for turn ends that must not leave a list sliding behind.
func CloseInstantly() -> void:
	if(null != _slide_tween):
		_slide_tween.kill()
	_is_open = false
	var pouch_positions: Array[Vector2] = _PouchPositions()
	for i in _reagent_buttons.size():
		_reagent_buttons[i].position = pouch_positions[i]
	_reagent_list.modulate.a = 0.0
	_backdrop.material.set_shader_parameter("reveal", 0.0)
	_on_close_finished()

# The fade rides the list rather than each button, whose modulate marks a spent reagent.
func _SlideTo(p_targets: Array[Vector2], p_target_visibility: float, p_on_finished: Callable) -> void:
	if(null != _slide_tween):
		_slide_tween.kill()
	_reagent_list.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	_slide_tween = create_tween().set_parallel(true)
	_slide_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	for i in _reagent_buttons.size():
		_slide_tween.tween_property(_reagent_buttons[i], "position", p_targets[i], SLIDE_DURATION)
	_slide_tween.tween_property(_reagent_list, "modulate:a", p_target_visibility, SLIDE_DURATION)
	_slide_tween.tween_property(_backdrop.material, "shader_parameter/reveal", p_target_visibility, SLIDE_DURATION)
	_slide_tween.chain().tween_callback(p_on_finished)

# Each reagent's position, in the list's space, that centres it on the pouch button.
func _PouchPositions() -> Array[Vector2]:
	var pouch_center: Vector2 = _pouch_button.position + _pouch_button.size * 0.5 - _reagent_list.position
	var positions: Array[Vector2] = []
	for button in _reagent_buttons:
		positions.append(pouch_center - button.size * 0.5)
	return positions

func _on_open_finished() -> void:
	_reagent_list.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED

func _on_close_finished() -> void:
	_reagent_list.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	_reagent_list.hide()
	_backdrop.hide()

func _on_pouch_button_button_up() -> void:
	Toggle()
