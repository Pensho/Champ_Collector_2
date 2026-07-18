extends GutTest

## Coverage for Scripts/Battle/reagent_loadout.gd: once-per-battle enforcement and
## inventory deletion, kept independent of the Battle scene node so this is testable
## headlessly (Test_Design_Document.md: test pure logic, not node trees).

const A_REAGENT_KEY: String = "Tincture_Speed_Uncommon"
const ANOTHER_REAGENT_KEY: String = "Restorative_Draught_Rare"

func test_try_consume_marks_spent_and_consumes_from_collection() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Add(A_REAGENT_KEY)
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY])

	assert_true(loadout.TryConsume(0, collection))

	assert_true(loadout.IsSpent(0))
	assert_eq(collection.GetCount(A_REAGENT_KEY), 0)
	collection.free()

func test_try_consume_twice_only_deletes_once() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Add(A_REAGENT_KEY, 2)
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY])

	assert_true(loadout.TryConsume(0, collection))
	assert_false(loadout.TryConsume(0, collection), "A second consumption of the same slot must be rejected")

	assert_eq(collection.GetCount(A_REAGENT_KEY), 1, "Only the first TryConsume should have deleted from the inventory")
	collection.free()

func test_try_consume_out_of_range_returns_false() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	var loadout: ReagentLoadout = ReagentLoadout.new([])

	assert_false(loadout.TryConsume(0, collection))
	assert_false(loadout.TryConsume(-1, collection))
	collection.free()

func test_untouched_loadout_never_reduces_the_collection() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Add(A_REAGENT_KEY)
	collection.Add(ANOTHER_REAGENT_KEY)
	ReagentLoadout.new([A_REAGENT_KEY, ANOTHER_REAGENT_KEY])

	assert_eq(collection.GetCount(A_REAGENT_KEY), 1,
			"Reagents brought but never consumed must still be owned (they return to the inventory)")
	assert_eq(collection.GetCount(ANOTHER_REAGENT_KEY), 1)
	collection.free()

func test_size_and_key_at() -> void:
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY, ANOTHER_REAGENT_KEY])

	assert_eq(loadout.Size(), 2)
	assert_eq(loadout.KeyAt(0), A_REAGENT_KEY)
	assert_eq(loadout.KeyAt(1), ANOTHER_REAGENT_KEY)
	assert_false(loadout.IsSpent(0))
