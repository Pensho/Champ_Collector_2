extends GutTest

func before_each() -> void:
	# Step past any frame a previous test consumed a press on, then start a fresh press.
	await wait_process_frames(1)
	ToolTip.RegisterPress()

func test_press_without_tooltip_is_not_consumed() -> void:
	assert_false(ToolTip.ConsumedPress(), "A press that opened no tooltip should reach the control underneath.")

func test_opening_tooltip_consumes_press() -> void:
	ToolTip.MarkPressConsumed()
	assert_true(ToolTip.ConsumedPress(), "The release ending a tooltip hold should be ignored.")

func test_next_press_clears_consumption() -> void:
	ToolTip.MarkPressConsumed()
	await wait_process_frames(1)
	ToolTip.RegisterPress()
	assert_false(ToolTip.ConsumedPress(), "A new press should start unconsumed.")

func test_same_frame_registration_keeps_consumption() -> void:
	ToolTip.MarkPressConsumed()
	ToolTip.RegisterPress()
	assert_true(ToolTip.ConsumedPress(), "Another tooltip registering the same press must not undo a show_on_press consumption.")
