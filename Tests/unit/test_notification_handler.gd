extends GutTest

func _make_handler() -> NotificationHandler:
	var handler: NotificationHandler = NotificationHandler.new()
	add_child_autoqfree(handler)
	return handler

func test_notify_with_nothing_active_becomes_active() -> void:
	var handler: NotificationHandler = _make_handler()
	handler.Notify("Game saved")
	assert_not_null(handler._active, "First notification should become active immediately")
	assert_true(handler._queue.is_empty(), "Queue should be empty once the first notification is active")

func test_second_notify_is_queued_not_shown() -> void:
	var handler: NotificationHandler = _make_handler()
	handler.Notify("First")
	var first_active: NotificationBox = handler._active
	handler.Notify("Second")
	assert_eq(handler._active, first_active, "Active notification should not change while one is showing")
	assert_eq(handler._queue.size(), 1, "Second notification should wait in the queue")

func test_finishing_active_promotes_queued() -> void:
	var handler: NotificationHandler = _make_handler()
	handler.Notify("First")
	handler.Notify("Second")
	handler._on_notification_finished()
	assert_not_null(handler._active, "Queued notification should become active once the first finishes")
	assert_true(handler._queue.is_empty(), "Queue should be empty once the queued notification is promoted")

func test_finishing_last_notification_clears_state() -> void:
	var handler: NotificationHandler = _make_handler()
	handler.Notify("Only one")
	handler._on_notification_finished()
	assert_null(handler._active, "No notification should be active once the last one finishes")
	assert_true(handler._queue.is_empty(), "Queue should stay empty with nothing left to show")

func test_queue_is_capped_at_max_length() -> void:
	var handler: NotificationHandler = _make_handler()
	handler.Notify("Active")
	for i in NotificationHandler.MAX_QUEUE_LENGTH + 3:
		handler.Notify("Queued " + str(i))
	assert_eq(handler._queue.size(), NotificationHandler.MAX_QUEUE_LENGTH,
		"Queue should never grow past MAX_QUEUE_LENGTH")

func test_notify_defaults_to_info_kind() -> void:
	var handler: NotificationHandler = _make_handler()
	handler.Notify("Plain message")
	handler.Notify("Second message")
	assert_eq(handler._queue[0]["kind"], Types.Notification_Kind.Info,
		"Notify should default to Info when no kind is given")
