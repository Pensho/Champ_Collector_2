class_name TapGesture extends RefCounted

## Tells a tap apart from a drag: a press stays a tap until the pointer travels
## further than MOVE_THRESHOLD from where it went down. Matches the ScrollContainer
## scroll_deadzone so a press either scrolls the list or activates the slot, never both.
const MOVE_THRESHOLD: float = 12.0

var _press_position: Vector2 = Vector2.ZERO
var _is_drag: bool = false

func Press(p_position: Vector2) -> void:
	_press_position = p_position
	_is_drag = false

func Move(p_position: Vector2) -> void:
	if _press_position.distance_to(p_position) > MOVE_THRESHOLD:
		_is_drag = true

func IsTap() -> bool:
	return not _is_drag

func HandleEvent(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = p_event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			Press(mouse_button.global_position)
	elif p_event is InputEventMouseMotion:
		Move((p_event as InputEventMouseMotion).global_position)
