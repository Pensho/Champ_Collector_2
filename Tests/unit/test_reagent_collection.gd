extends GutTest

# Coverage for Scripts/Gear/reagent_collection.gd, parallel to test_collection_serialization.gd's
# ItemCollection section (Plan_Reagent_Inventory_And_Storage_UI.md step 4).

const A_REAGENT_KEY: String = "Tincture_Speed_Uncommon"
const ANOTHER_REAGENT_KEY: String = "Restorative_Draught_Rare"

func test_add_increments_count() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Add(A_REAGENT_KEY)
	collection.Add(A_REAGENT_KEY, 2)
	assert_eq(collection.GetCount(A_REAGENT_KEY), 3, "Add should accumulate counts")
	collection.free()

func test_consume_decrements_and_erases_at_zero() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Add(A_REAGENT_KEY, 2)
	assert_true(collection.Consume(A_REAGENT_KEY), "Consume should succeed while owned")
	assert_eq(collection.GetCount(A_REAGENT_KEY), 1, "Consume should decrement by one")
	assert_true(collection.Consume(A_REAGENT_KEY), "Consume should succeed on the last one")
	assert_eq(collection.GetCount(A_REAGENT_KEY), 0, "Count should be zero after consuming the last one")
	assert_false(collection.GetAllOwned().has(A_REAGENT_KEY), "Entry should be erased once count hits zero")
	collection.free()

func test_consume_absent_key_returns_false() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	assert_false(collection.Consume(A_REAGENT_KEY), "Consume on an absent key should return false")
	collection.free()

func test_serialize_deserialize_roundtrip() -> void:
	var col1: ReagentCollection = ReagentCollection.new()
	col1.Add(A_REAGENT_KEY, 2)
	col1.Add(ANOTHER_REAGENT_KEY, 1)

	var data: Dictionary = col1.Serialize()

	var col2: ReagentCollection = ReagentCollection.new()
	col2.Deserialize(data)

	assert_eq(col2.GetCount(A_REAGENT_KEY), 2, "First reagent's count must survive roundtrip")
	assert_eq(col2.GetCount(ANOTHER_REAGENT_KEY), 1, "Second reagent's count must survive roundtrip")
	col1.free()
	col2.free()

func test_deserialize_tolerates_missing_data() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Deserialize({})
	assert_eq(collection.GetAllOwned().size(), 0, "Deserializing a pre-reagent save should leave an empty collection")
	collection.free()

func test_deserialize_skips_unknown_registry_keys() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Deserialize({"counts": {A_REAGENT_KEY: 1, "Nonexistent_Reagent_Key": 5}})
	assert_eq(collection.GetCount(A_REAGENT_KEY), 1, "Known reagent keys should still load")
	assert_false(
			collection.GetAllOwned().has("Nonexistent_Reagent_Key"),
			"Stale keys no longer in the registry should be skipped")
	collection.free()
