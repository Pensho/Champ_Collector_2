extends GutTest

var _handler: AdventureStateHandler

func before_each() -> void:
	_handler = AdventureStateHandler.new()
	_handler._state.is_active = true
	_handler._state.difficulty = 3
	_handler._state.current_node_index = 4

func after_each() -> void:
	_handler.free()

func test_reset_ends_the_run() -> void:
	_handler.Reset()
	assert_false(_handler._state.is_active, "A reset run must no longer be active.")
	assert_eq(_handler._state.current_node_index, AdventureState.new().current_node_index,
			"A reset run must not keep its position.")

func test_reset_run_is_not_saved() -> void:
	assert_false(_handler.Serialize().is_empty(), "An active run must be saved.")
	_handler.Reset()
	assert_true(_handler.Serialize().is_empty(), "A reset run must leave nothing to save.")
