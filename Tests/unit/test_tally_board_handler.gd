extends GutTest

func test_restock_not_due_below_interval() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var anchor: int = now - 1800
	assert_false(TallyBoardHandler.IsRestockDue(anchor, now), "Should not be due before the interval elapses")


func test_restock_due_at_interval() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var anchor: int = now - GameBalance.TALLY_BOARD_RESTOCK_INTERVAL_SECONDS
	assert_true(TallyBoardHandler.IsRestockDue(anchor, now), "Should be due exactly at the interval")


func test_restock_due_when_anchor_unset() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	assert_true(TallyBoardHandler.IsRestockDue(0, now), "Should be due when the anchor is unset")


func test_countdown_seconds_at_boundaries() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	assert_eq(TallyBoardHandler.GetSecondsUntilRestock(now, now), GameBalance.TALLY_BOARD_RESTOCK_INTERVAL_SECONDS,
			"Full interval should remain right after a restock")
	assert_eq(TallyBoardHandler.GetSecondsUntilRestock(now - GameBalance.TALLY_BOARD_RESTOCK_INTERVAL_SECONDS, now), 0,
			"Should be zero once due")


func test_price_matches_rarity_table() -> void:
	assert_eq(TallyBoardHandler.GetPrice(Types.Rarity.Rare), GameBalance.TALLY_BOARD_PRICE_PER_RARITY[Types.Rarity.Rare],
			"Price should come straight from the rarity table")


func test_roll_offers_returns_distinct_champions() -> void:
	var offers: Array[Dictionary] = TallyBoardHandler.RollOffers()

	assert_eq(offers.size(), GameBalance.TALLY_BOARD_SLOTS, "Should roll exactly the configured slot count")
	var seen: Dictionary[String, bool] = {}
	for entry in offers:
		assert_false(seen.has(entry["preset_path"]), "Offers should not repeat the same champion")
		seen[entry["preset_path"]] = true
		assert_eq(entry["price"], TallyBoardHandler.GetPrice(entry["rarity"]), "Offer price should match its rarity")
		assert_false(entry["sold_out"], "A freshly rolled offer should not be sold out")


func test_ensure_fresh_rolls_offers_when_due() -> void:
	var board: TallyBoardHandler = TallyBoardHandler.new()
	board._restock_anchor_unix = 0

	board.EnsureFresh()

	assert_eq(board._offers.size(), GameBalance.TALLY_BOARD_SLOTS, "Should roll a full set of offers")
	assert_true(board._restock_anchor_unix > 0, "Anchor should be set once rolled")
	board.free()


func test_purchase_refuses_when_sold_out() -> void:
	var board: TallyBoardHandler = TallyBoardHandler.new()
	add_child_autofree(board)
	board._offers = TallyBoardHandler.RollOffers()
	board._offers[0]["sold_out"] = true

	assert_false(board.Purchase(0), "A sold out offer should refuse purchase")


func test_purchase_refuses_when_tallies_insufficient() -> void:
	var board: TallyBoardHandler = TallyBoardHandler.new()
	add_child_autofree(board)
	board._offers = TallyBoardHandler.RollOffers()
	main.GetInstance()._resources._tallies = 0

	assert_false(board.Purchase(0), "Purchase should refuse when Tallies are insufficient")
	assert_false(board._offers[0]["sold_out"], "A refused purchase should not mark the offer sold out")


func test_purchase_refuses_when_roster_full() -> void:
	var board: TallyBoardHandler = TallyBoardHandler.new()
	add_child_autofree(board)
	board._offers = TallyBoardHandler.RollOffers()
	main.GetInstance()._resources._tallies = 999999
	main.GetInstance()._character_collection._current_max_amount = main.GetInstance()._character_collection.Size()

	assert_false(board.Purchase(0), "Purchase should refuse when the roster is full")

	main.GetInstance()._character_collection._current_max_amount = GameBalance.COLLECTION_START_ROSTER_SIZE


func test_purchase_deducts_tallies_exactly_once_on_success() -> void:
	var board: TallyBoardHandler = TallyBoardHandler.new()
	add_child_autofree(board)
	board._offers = TallyBoardHandler.RollOffers()
	var price: int = board._offers[0]["price"]
	main.GetInstance()._resources._tallies = price

	assert_true(board.Purchase(0), "Purchase should succeed with exactly enough Tallies")
	assert_eq(main.GetInstance()._resources.GetTallies(), 0, "Tallies should be spent exactly once")
	assert_true(board._offers[0]["sold_out"], "A successful purchase should mark the offer sold out")
	assert_false(board.Purchase(0), "A second purchase of the same slot should refuse")


func test_serialize_deserialize_round_trip_survives_json() -> void:
	var board: TallyBoardHandler = TallyBoardHandler.new()
	board._offers = TallyBoardHandler.RollOffers()
	board._offers[0]["sold_out"] = true
	board._restock_anchor_unix = int(Time.get_unix_time_from_system())

	var json_data: Dictionary = JSON.parse_string(JSON.stringify(board.Serialize()))

	var board2: TallyBoardHandler = TallyBoardHandler.new()
	board2.Deserialize(json_data)

	assert_eq(board2._offers.size(), board._offers.size(), "Offer count should round-trip through JSON")
	assert_eq(board2._offers[0]["sold_out"], true, "Sold out flag should round-trip through JSON")
	assert_eq(board2._offers[0]["preset_path"], board._offers[0]["preset_path"],
			"Preset path should round-trip through JSON")
	assert_eq(typeof(board2._offers[0]["rarity"]), TYPE_INT, "Rarity should be cast back to int after a JSON round-trip")
	assert_eq(board2._restock_anchor_unix, board._restock_anchor_unix, "Restock anchor should round-trip through JSON")
	board.free()
	board2.free()
