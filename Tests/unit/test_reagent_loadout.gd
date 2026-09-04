extends GutTest

## Coverage for Scripts/Battle/reagent_loadout.gd: once-per-battle enforcement and
## inventory deletion, kept independent of the Battle scene node so this is testable
## headlessly (Test_Design_Document.md: test pure logic, not node trees).

const A_REAGENT_KEY: String = "Sigil_Speed_Uncommon"
const ANOTHER_REAGENT_KEY: String = "Mending_Icon_Rare"

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

func test_add_brewed_appends_an_unspent_consumable_slot() -> void:
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY])

	loadout.AddBrewed("Lesser_Restorative_Brew", 0.1)

	assert_eq(loadout.Size(), 2)
	assert_eq(loadout.KeyAt(1), "Lesser_Restorative_Brew")
	assert_false(loadout.IsSpent(1))
	assert_almost_eq(loadout.PotencyBonusAt(1), 0.1, 0.001)
	assert_almost_eq(loadout.PotencyBonusAt(0), 0.0, 0.001, "Brought reagents keep a zero potency bonus")

func test_try_consume_on_a_brewed_slot_never_touches_the_collection() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	var loadout: ReagentLoadout = ReagentLoadout.new([])
	loadout.AddBrewed("Lesser_Restorative_Brew", 0.0)

	assert_true(loadout.TryConsume(0, collection))

	assert_true(loadout.IsSpent(0))
	assert_eq(collection.GetCount("Lesser_Restorative_Brew"), 0,
			"A brewed slot must never be added to or removed from the persistent inventory")
	collection.free()

func test_is_brewed_reflects_the_slot_origin() -> void:
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY])
	loadout.AddBrewed("Lesser_Restorative_Brew", 0.0)

	assert_false(loadout.IsBrewed(0))
	assert_true(loadout.IsBrewed(1))

func test_refill_with_brew_restores_a_spent_slot_as_brewed() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Add(A_REAGENT_KEY)
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY])
	loadout.TryConsume(0, collection)

	assert_true(loadout.RefillWithBrew(0, "Lesser_Barrier_Brew", 0.1))

	assert_false(loadout.IsSpent(0))
	assert_true(loadout.IsBrewed(0))
	assert_eq(loadout.KeyAt(0), "Lesser_Barrier_Brew")
	assert_almost_eq(loadout.PotencyBonusAt(0), 0.1, 0.001)
	collection.free()

func test_refill_with_brew_rejects_an_unspent_slot() -> void:
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY])

	assert_false(loadout.RefillWithBrew(0, "Lesser_Barrier_Brew", 0.1))
	assert_eq(loadout.KeyAt(0), A_REAGENT_KEY, "An unspent slot must not be overwritten")

func test_refill_with_brew_rejects_out_of_range_index() -> void:
	var loadout: ReagentLoadout = ReagentLoadout.new([])

	assert_false(loadout.RefillWithBrew(0, "Lesser_Barrier_Brew", 0.1))
	assert_false(loadout.RefillWithBrew(-1, "Lesser_Barrier_Brew", 0.1))

func test_refilled_slot_is_dropped_by_get_reagents_for_context_and_never_hits_the_collection() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Add(A_REAGENT_KEY)
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY])
	loadout.TryConsume(0, collection)
	loadout.RefillWithBrew(0, "Lesser_Barrier_Brew", 0.0)

	assert_true(loadout.TryConsume(0, collection))

	assert_eq(collection.GetCount("Lesser_Barrier_Brew"), 0,
			"A refunded brew must never be added to or removed from the persistent inventory")
	assert_eq(loadout.GetReagentsForContext(), [],
			"A refilled-then-consumed slot must not persist into the next battle's context")
	collection.free()
