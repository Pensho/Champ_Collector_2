extends GutTest

func test_restock_not_due_below_interval() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var anchor: int = now - 1800
	assert_false(ShopHandler.IsRestockDue(anchor, now), "Should not be due before the interval elapses")


func test_restock_due_at_interval() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var anchor: int = now - GameBalance.SHOP_RESTOCK_INTERVAL_SECONDS
	assert_true(ShopHandler.IsRestockDue(anchor, now), "Should be due exactly at the interval")


func test_restock_due_past_interval() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var anchor: int = now - GameBalance.SHOP_RESTOCK_INTERVAL_SECONDS - 100
	assert_true(ShopHandler.IsRestockDue(anchor, now), "Should be due past the interval")


func test_restock_due_when_anchor_unset() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	assert_true(ShopHandler.IsRestockDue(0, now), "Should be due when the anchor is unset")


func test_multi_hour_absence_yields_single_reroll_with_anchor_at_now() -> void:
	var shop: ShopHandler = ShopHandler.new()
	var now: int = int(Time.get_unix_time_from_system())
	shop._restock_anchor_unix = now - (GameBalance.SHOP_RESTOCK_INTERVAL_SECONDS * 5)

	shop.EnsureFresh()

	assert_eq(shop._stock.size(), GameBalance.SHOP_SLOT_COUNT, "Should reroll exactly once regardless of elapsed intervals")
	assert_true(shop._restock_anchor_unix >= now, "Anchor should jump to now rather than carrying a remainder")
	shop.free()


func test_countdown_seconds_at_boundaries() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	assert_eq(ShopHandler.GetSecondsUntilRestock(now, now), GameBalance.SHOP_RESTOCK_INTERVAL_SECONDS,
			"Full interval should remain right after a restock")
	assert_eq(ShopHandler.GetSecondsUntilRestock(now - GameBalance.SHOP_RESTOCK_INTERVAL_SECONDS, now), 0,
			"Should be zero once due")


func test_favor_available_when_never_purchased() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	assert_true(ShopHandler.IsFavorAvailable(0, now), "Should be available when never purchased")


func test_favor_blocked_inside_three_days() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var last_purchase: int = now - (GameBalance.SHOP_FORTUNES_FAVOR_COOLDOWN_SECONDS - 100)
	assert_false(ShopHandler.IsFavorAvailable(last_purchase, now), "Should be blocked inside the cooldown")


func test_favor_available_at_exactly_three_days() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var last_purchase: int = now - GameBalance.SHOP_FORTUNES_FAVOR_COOLDOWN_SECONDS
	assert_true(ShopHandler.IsFavorAvailable(last_purchase, now), "Should be available exactly at the cooldown boundary")


func test_roll_stock_returns_slot_count_with_expected_split() -> void:
	var stock: Array[Dictionary] = ShopHandler.RollStock(5000)

	assert_eq(stock.size(), GameBalance.SHOP_SLOT_COUNT, "Should build all six slots")
	for i in range(0, GameBalance.SHOP_GEAR_SLOTS):
		assert_eq(stock[i]["category"], Types.Category.Gear, "First three slots should be gear")
	assert_eq(stock[3]["category"], Types.Category.Reagent, "Fourth slot should be reagent")
	assert_eq(stock[4]["category"], Types.Category.Supplies, "Fifth slot should be supplies")
	assert_eq(stock[5]["category"], Types.Category.FortunesFavor, "Sixth slot should be Fortune's Favor")
	for entry in stock:
		assert_true(entry["price"] > 0, "Every slot should have a positive price")


func test_roll_stock_gear_entries_have_already_rolled_attributes() -> void:
	var stock: Array[Dictionary] = ShopHandler.RollStock(5000)

	for i in range(0, GameBalance.SHOP_GEAR_SLOTS):
		var entry: Dictionary = stock[i]
		var total: int = 0
		for attribute_name in entry["attributes"].keys():
			total += entry["attributes"][attribute_name]
		var expected_total: int = int(entry["rarity"]) * GameBalance.ITEM_ATTRIBUTE_PER_RARITY
		assert_eq(total, expected_total, "Rolled attribute total should match the entry's rarity")


func test_gear_price_matches_sell_value_times_markup() -> void:
	var expected: int = int(LootManager.GetSellValue(Types.Rarity.Rare) * GameBalance.SHOP_BUY_MARKUP)
	assert_eq(ShopHandler.GetGearPrice(Types.Rarity.Rare), expected, "Gear price should equal sell value times markup")


func test_reagent_price_matches_sell_value_times_markup() -> void:
	var expected: int = int(LootManager.GetReagentSellValue(Types.Rarity.Epic) * GameBalance.SHOP_BUY_MARKUP)
	assert_eq(ShopHandler.GetReagentPrice(Types.Rarity.Epic), expected, "Reagent price should equal sell value times markup")


func test_serialize_deserialize_round_trip_survives_json() -> void:
	var shop: ShopHandler = ShopHandler.new()
	shop._stock = ShopHandler.RollStock(5000)
	shop._stock[0]["sold_out"] = true
	shop._restock_anchor_unix = int(Time.get_unix_time_from_system())
	shop._favor_purchase_unix = shop._restock_anchor_unix - 1000

	var json_data: Dictionary = JSON.parse_string(JSON.stringify(shop.Serialize()))

	var shop2: ShopHandler = ShopHandler.new()
	shop2.Deserialize(json_data)

	assert_eq(shop2._stock.size(), shop._stock.size(), "Stock size should round-trip through JSON")
	assert_eq(shop2._stock[0]["sold_out"], true, "Sold out flag should round-trip through JSON")
	assert_eq(shop2._stock[0]["category"], int(shop._stock[0]["category"]), "Category should round-trip through JSON")
	assert_eq(typeof(shop2._stock[0]["rarity"]), TYPE_INT, "Rarity should be cast back to int after a JSON round-trip")
	assert_eq(shop2._restock_anchor_unix, shop._restock_anchor_unix, "Restock anchor should round-trip through JSON")
	assert_eq(shop2._favor_purchase_unix, shop._favor_purchase_unix, "Favor purchase timestamp should round-trip through JSON")
	assert_eq(
			shop2._stock[0]["attributes"], shop._stock[0]["attributes"],
			"Rolled gear attributes should round-trip through JSON")
	shop.free()
	shop2.free()
