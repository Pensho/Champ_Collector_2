extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func _make_collection(p_levels: Dictionary) -> Dictionary[int, Character]:
	var collection: Dictionary[int, Character] = {}
	for character_id in p_levels.keys():
		var character: Character = TestFactory.make_character()
		character._level = p_levels[character_id]
		collection[character_id] = character
	return collection

func test_descending_puts_highest_level_first() -> void:
	var collection: Dictionary[int, Character] = _make_collection({0: 3, 1: 10, 2: 6})
	var ids: Array[int] = collection.keys()

	var sorted_ids: Array[int] = InspectCollectionMenu.SortCharacterIDsByLevel(collection, ids, true)

	assert_eq(sorted_ids, [1, 2, 0])

func test_ascending_is_exact_reverse_of_descending() -> void:
	var collection: Dictionary[int, Character] = _make_collection({0: 3, 1: 10, 2: 6})
	var ids: Array[int] = collection.keys()

	var sorted_ids: Array[int] = InspectCollectionMenu.SortCharacterIDsByLevel(collection, ids, false)

	assert_eq(sorted_ids, [0, 2, 1])

func test_equal_levels_tie_break_by_character_id_ascending_when_descending() -> void:
	var collection: Dictionary[int, Character] = _make_collection({5: 4, 1: 4, 3: 4})
	var ids: Array[int] = collection.keys()

	var sorted_ids: Array[int] = InspectCollectionMenu.SortCharacterIDsByLevel(collection, ids, true)

	assert_eq(sorted_ids, [1, 3, 5])

func test_equal_levels_tie_break_by_character_id_ascending_when_ascending() -> void:
	var collection: Dictionary[int, Character] = _make_collection({5: 4, 1: 4, 3: 4})
	var ids: Array[int] = collection.keys()

	var sorted_ids: Array[int] = InspectCollectionMenu.SortCharacterIDsByLevel(collection, ids, false)

	assert_eq(sorted_ids, [1, 3, 5])

func test_empty_collection_returns_empty_array() -> void:
	var collection: Dictionary[int, Character] = {}
	var ids: Array[int] = []

	var sorted_ids: Array[int] = InspectCollectionMenu.SortCharacterIDsByLevel(collection, ids, true)

	assert_eq(sorted_ids.size(), 0)

func test_single_entry_is_returned_unchanged() -> void:
	var collection: Dictionary[int, Character] = _make_collection({7: 12})
	var ids: Array[int] = collection.keys()

	var sorted_ids: Array[int] = InspectCollectionMenu.SortCharacterIDsByLevel(collection, ids, true)

	assert_eq(sorted_ids, [7])

func test_input_array_is_not_mutated() -> void:
	var collection: Dictionary[int, Character] = _make_collection({0: 3, 1: 10, 2: 6})
	var ids: Array[int] = collection.keys()
	var original_order: Array[int] = ids.duplicate()

	InspectCollectionMenu.SortCharacterIDsByLevel(collection, ids, true)

	assert_eq(ids, original_order)
