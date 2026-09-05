extends GutTest

func test_selected_slot_is_dimmed() -> void:
	var modulate: Color = InspectCollectionMenu.GetSlotModulate(5, 5)

	assert_eq(modulate, Color(0.45, 0.45, 0.45, 1.0))

func test_unselected_slot_is_full_bright() -> void:
	var modulate: Color = InspectCollectionMenu.GetSlotModulate(5, 3)

	assert_eq(modulate, Color(1.0, 1.0, 1.0, 1.0))

func test_no_selection_is_full_bright() -> void:
	var modulate: Color = InspectCollectionMenu.GetSlotModulate(5, -1)

	assert_eq(modulate, Color(1.0, 1.0, 1.0, 1.0))
