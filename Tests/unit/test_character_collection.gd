extends GutTest

func test_roster_slot_price_at_start_size() -> void:
	assert_eq(CharacterCollection.GetRosterSlotPrice(Game_Balance.COLLECTION_START_ROSTER_SIZE),
			Game_Balance.ROSTER_SLOT_BASE_PRICE, "The first purchase should cost the flat base price")


func test_roster_slot_price_rises_with_each_purchased_increment() -> void:
	var current_max: int = Game_Balance.COLLECTION_START_ROSTER_SIZE + Game_Balance.COLLECTION_SIZE_INCREMENT
	assert_eq(CharacterCollection.GetRosterSlotPrice(current_max),
			Game_Balance.ROSTER_SLOT_BASE_PRICE + Game_Balance.ROSTER_SLOT_PRICE_INCREMENT,
			"Each purchased increment should add one price step")

	var further_max: int = current_max + Game_Balance.COLLECTION_SIZE_INCREMENT
	assert_eq(CharacterCollection.GetRosterSlotPrice(further_max),
			Game_Balance.ROSTER_SLOT_BASE_PRICE + Game_Balance.ROSTER_SLOT_PRICE_INCREMENT * 2,
			"Price should keep rising with further purchases")


func test_increase_collection_size_succeeds_and_returns_true() -> void:
	var collection: CharacterCollection = CharacterCollection.new()
	var starting_max: int = collection._current_max_amount

	assert_true(collection.IncreaseCollectionSize(), "Increasing size below the cap should succeed")
	assert_eq(collection._current_max_amount, starting_max + Game_Balance.COLLECTION_SIZE_INCREMENT,
			"Max amount should grow by exactly one increment")

	collection.free()


func test_increase_collection_size_refuses_at_the_cap() -> void:
	var collection: CharacterCollection = CharacterCollection.new()
	collection._current_max_amount = Game_Balance.COLLECTION_LIMIT

	assert_false(collection.IncreaseCollectionSize(), "Increasing size at the cap should refuse")
	assert_eq(collection._current_max_amount, Game_Balance.COLLECTION_LIMIT,
			"Max amount should not change when refused")

	collection.free()


func test_is_roster_at_max_size_true_only_within_the_final_increment() -> void:
	var collection: CharacterCollection = CharacterCollection.new()
	collection._current_max_amount = Game_Balance.COLLECTION_LIMIT - Game_Balance.COLLECTION_SIZE_INCREMENT
	assert_false(collection.IsRosterAtMaxSize(), "One increment below the limit should still allow a purchase")

	collection._current_max_amount = Game_Balance.COLLECTION_LIMIT
	assert_true(collection.IsRosterAtMaxSize(), "At the limit, no further purchase should be allowed")

	collection.free()
