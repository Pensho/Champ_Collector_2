extends GutTest

var _gesture: TapGesture

func before_each() -> void:
	_gesture = TapGesture.new()

func _MouseButton(p_position: Vector2, p_pressed: bool) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = p_pressed
	event.global_position = p_position
	return event

func _MouseMotion(p_position: Vector2) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.global_position = p_position
	return event

func test_press_without_movement_is_tap() -> void:
	_gesture.Press(Vector2(100, 100))
	assert_true(_gesture.IsTap(), "A press that never moves should count as a tap.")

func test_jitter_within_threshold_is_tap() -> void:
	_gesture.Press(Vector2(100, 100))
	_gesture.Move(Vector2(100 + TapGesture.MOVE_THRESHOLD, 100))
	assert_true(_gesture.IsTap(), "Movement up to the threshold should still count as a tap.")

func test_movement_past_threshold_is_drag() -> void:
	_gesture.Press(Vector2(100, 100))
	_gesture.Move(Vector2(100, 100 + TapGesture.MOVE_THRESHOLD + 1.0))
	assert_false(_gesture.IsTap(), "Movement past the threshold should count as a drag.")

func test_returning_to_press_position_stays_drag() -> void:
	_gesture.Press(Vector2(100, 100))
	_gesture.Move(Vector2(100, 200))
	_gesture.Move(Vector2(100, 100))
	assert_false(_gesture.IsTap(), "A drag that returns to its start should not become a tap again.")

func test_new_press_resets_drag() -> void:
	_gesture.Press(Vector2(100, 100))
	_gesture.Move(Vector2(100, 200))
	_gesture.Press(Vector2(300, 300))
	assert_true(_gesture.IsTap(), "A new press should start a fresh tap.")

func test_handle_event_tracks_press_and_motion() -> void:
	_gesture.HandleEvent(_MouseButton(Vector2(100, 100), true))
	_gesture.HandleEvent(_MouseMotion(Vector2(100, 200)))
	assert_false(_gesture.IsTap(), "Press then far motion events should count as a drag.")

func test_handle_event_release_does_not_reset() -> void:
	_gesture.HandleEvent(_MouseButton(Vector2(100, 100), true))
	_gesture.HandleEvent(_MouseMotion(Vector2(100, 200)))
	_gesture.HandleEvent(_MouseButton(Vector2(100, 200), false))
	assert_false(_gesture.IsTap(), "The release must not clear a drag before the click handler reads it.")
