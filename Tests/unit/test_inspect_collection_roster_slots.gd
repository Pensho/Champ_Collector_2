extends GutTest

func test_slot_holding_a_champion_is_filled() -> void:
	var state: int = InspectCollectionMenu.GetRosterSlotState(4, 5, 30)

	assert_eq(state, InspectCollectionMenu.RosterSlotState.Filled)

func test_slot_within_capacity_without_a_champion_is_empty() -> void:
	var state: int = InspectCollectionMenu.GetRosterSlotState(5, 5, 30)

	assert_eq(state, InspectCollectionMenu.RosterSlotState.Empty)

func test_last_slot_of_the_capacity_is_empty() -> void:
	var state: int = InspectCollectionMenu.GetRosterSlotState(29, 5, 30)

	assert_eq(state, InspectCollectionMenu.RosterSlotState.Empty)

func test_slot_beyond_capacity_is_unavailable() -> void:
	var state: int = InspectCollectionMenu.GetRosterSlotState(30, 5, 30)

	assert_eq(state, InspectCollectionMenu.RosterSlotState.Unavailable)

func test_a_full_roster_has_no_empty_slots() -> void:
	for slot_nr in 30:
		assert_eq(InspectCollectionMenu.GetRosterSlotState(slot_nr, 30, 30),
				InspectCollectionMenu.RosterSlotState.Filled)

func test_champion_beyond_capacity_stays_visible() -> void:
	var state: int = InspectCollectionMenu.GetRosterSlotState(30, 31, 30)

	assert_eq(state, InspectCollectionMenu.RosterSlotState.Filled)

func test_bought_capacity_turns_unavailable_slots_into_empty_ones() -> void:
	var before: int = InspectCollectionMenu.GetRosterSlotState(30, 5, 30)
	var after: int = InspectCollectionMenu.GetRosterSlotState(
			30, 5, 30 + Game_Balance.COLLECTION_SIZE_INCREMENT)

	assert_eq(before, InspectCollectionMenu.RosterSlotState.Unavailable)
	assert_eq(after, InspectCollectionMenu.RosterSlotState.Empty)
