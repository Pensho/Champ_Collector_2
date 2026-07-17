extends GutTest

# Coverage for the reagent loot-integration pieces of LootManager/LootTable/ReagentRegistry
# (Plan_Reagent_Inventory_And_Storage_UI.md step 4), parallel in style to test_loot_manager.gd.

func test_roll_rarity_for_reagent_respects_max_rarity_cap() -> void:
	for i in range(200):
		var rolled: Types.Rarity = LootManager.RollRarityForReagent(Types.Rarity.Legendary, Types.Rarity.Epic)
		assert_true(rolled >= Types.Rarity.Uncommon, "Rolled rarity should never be below Uncommon")
		assert_true(rolled <= Types.Rarity.Epic, "Rolled rarity should never exceed the given max_rarity cap")

func test_roll_rarity_for_reagent_never_below_uncommon() -> void:
	for i in range(200):
		var rolled: Types.Rarity = LootManager.RollRarityForReagent(Types.Rarity.Uncommon, Types.Rarity.Legendary)
		assert_eq(rolled, Types.Rarity.Uncommon, "A best_outcome of Uncommon should always roll Uncommon")

func test_roll_rarity_for_reagent_can_reach_legendary_when_capped_at_legendary() -> void:
	var saw_legendary: bool = false
	for i in range(300):
		if(LootManager.RollRarityForReagent(Types.Rarity.Legendary, Types.Rarity.Legendary) == Types.Rarity.Legendary):
			saw_legendary = true
			break
	assert_true(saw_legendary, "Legendary should be reachable when best_outcome and max_rarity are both Legendary")

func test_best_rarity_for_reagent_clamped_to_uncommon_through_legendary() -> void:
	assert_eq(
			LootManager.GetBestRarityForReagent(0),
			Types.Rarity.Uncommon as int,
			"Empty budget should clamp to Uncommon")
	assert_eq(
			LootManager.GetBestRarityForReagent(999999999),
			Types.Rarity.Legendary as int,
			"A huge budget should clamp to Legendary, never Relic")

func _reagent_primary_table(p_max_rarity: Types.Rarity) -> LootTable:
	var table := LootTable.new()
	table._primary_loot[LootManager.LootType.Reagent] = 1
	table._reagent_max_rarity = p_max_rarity
	table._budget = 3000
	return table

func test_dropped_reagent_keys_exist_in_registry() -> void:
	for i in range(30):
		var table: LootTable = _reagent_primary_table(Types.Rarity.Legendary)
		LootManager.DistributeRewards(table, 1)
		assert_eq(table._drop_result._reagents.size(), 1, "Distributing with a Reagent primary entry should drop one reagent")
		var reagent_key: String = table._drop_result._reagents[0]
		assert_true(
				ReagentRegistry.REAGENTS.has(reagent_key),
				"Dropped reagent key %s must exist in the registry" % reagent_key)

func test_primary_reagent_entry_yields_guaranteed_count() -> void:
	var table: LootTable = _reagent_primary_table(Types.Rarity.Epic)
	LootManager.DistributeRewards(table, 1)
	assert_eq(
			table._drop_result._reagents.size(),
			1,
			"A guaranteed primary Reagent entry of 1 should drop exactly one reagent")

func test_non_boss_cap_never_drops_legendary() -> void:
	for i in range(30):
		var table: LootTable = _reagent_primary_table(Types.Rarity.Epic)
		LootManager.DistributeRewards(table, 1)
		var reagent_key: String = table._drop_result._reagents[0]
		assert_true(
				ReagentRegistry.Get(reagent_key).rarity <= Types.Rarity.Epic,
				"Non-boss tables capped at Epic must never drop a Legendary reagent")

func test_reagent_sell_value_increases_with_rarity() -> void:
	var uncommon: int = LootManager.GetReagentSellValue(Types.Rarity.Uncommon)
	var rare: int = LootManager.GetReagentSellValue(Types.Rarity.Rare)
	var epic: int = LootManager.GetReagentSellValue(Types.Rarity.Epic)
	var legendary: int = LootManager.GetReagentSellValue(Types.Rarity.Legendary)
	assert_lt(uncommon, rare, "Rare should sell for more than Uncommon")
	assert_lt(rare, epic, "Epic should sell for more than Rare")
	assert_lt(epic, legendary, "Legendary should sell for more than Epic")

func test_selling_consumes_and_credits_at_the_collection_level() -> void:
	var collection: ReagentCollection = ReagentCollection.new()
	collection.Add("Tincture_Speed_Uncommon", 2)

	var sell_value: int = LootManager.GetReagentSellValue(ReagentRegistry.Get("Tincture_Speed_Uncommon").rarity)
	assert_gt(sell_value, 0, "Sell value should be positive")

	assert_true(collection.Consume("Tincture_Speed_Uncommon"), "Selling should be able to consume an owned reagent")
	assert_eq(collection.GetCount("Tincture_Speed_Uncommon"), 1, "Count should never go negative after selling")
	collection.free()

func test_random_key_for_rarity_matches_requested_rarity() -> void:
	for i in range(50):
		var reagent_key: String = ReagentRegistry.GetRandomKeyForRarity(Types.Rarity.Rare)
		assert_eq(ReagentRegistry.Get(reagent_key).rarity, Types.Rarity.Rare, "Returned key must match the requested rarity")
