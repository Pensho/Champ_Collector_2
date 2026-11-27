extends GutTest


func _ff_primary_table() -> LootTable:
	var table := LootTable.new()
	table._primary_loot[LootManager.LootType.Fortunes_Favor] = 1
	table._budget = 0
	return table


func test_ff_primary_diff_1_gives_1() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 1)
	assert_eq(table._drop_result._fortunes_favor.get(FortuneFavorTier.TierType.BONE, 0), 1, "Difficulty 1 should give 1 FF (minimum)")


func test_ff_primary_diff_2_gives_1() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 2)
	assert_eq(table._drop_result._fortunes_favor.get(FortuneFavorTier.TierType.BONE, 0), 1, "Difficulty 2 should still give 1 FF")


func test_ff_primary_diff_4_gives_2() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 4)
	assert_eq(table._drop_result._fortunes_favor.get(FortuneFavorTier.TierType.BONE, 0), 2, "Difficulty 4 should give 2 FF")


func test_ff_primary_diff_10_gives_5() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 10)
	assert_eq(table._drop_result._fortunes_favor.get(FortuneFavorTier.TierType.BONE, 0), 5, "Difficulty 10 should give 5 FF")


func test_ff_primary_diff_20_gives_10() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 20)
	assert_eq(table._drop_result._fortunes_favor.get(FortuneFavorTier.TierType.BONE, 0), 10, "Difficulty 20 should give 10 FF")


func test_ff_secondary_consumes_budget_for_one() -> void:
	var table := LootTable.new()
	table._secondary_loot[LootManager.LootType.Fortunes_Favor] = 1
	table._budget = 500
	LootManager.DistributeRewards(table, 1)
	assert_eq(table._drop_result._fortunes_favor.get(FortuneFavorTier.TierType.BONE, 0), 1, "500 budget with FF-only secondary should yield 1 FF")
	assert_lte(table._budget, 0, "Budget should be exhausted after 1 FF")


func test_best_fortune_favor_tier_low_budget_is_bone() -> void:
	assert_eq(LootManager.GetBestFortuneFavorTier(0), FortuneFavorTier.TierType.BONE, "Empty budget should cap at Bone tier")


func test_best_fortune_favor_tier_mid_budget_allows_brass() -> void:
	assert_eq(LootManager.GetBestFortuneFavorTier(12500), FortuneFavorTier.TierType.BRASS, "Budget around difficulty 10 should allow Brass tier")


func test_best_fortune_favor_tier_high_budget_allows_parchment() -> void:
	assert_eq(LootManager.GetBestFortuneFavorTier(28268), FortuneFavorTier.TierType.PARCHMENT, "Budget around difficulty 16-20 should allow Parchment tier")


func test_roll_fortune_favor_tier_within_range() -> void:
	var best_outcome := FortuneFavorTier.TierType.PARCHMENT as int
	var worst_outcome: int = max(best_outcome - LootManager.FORTUNE_FAVOR_TIER_RANGE, 0)
	for i in range(20):
		var rolled := LootManager.RollFortuneFavorTier(best_outcome) as int
		assert_between(rolled, worst_outcome, best_outcome, "Rolled tier should be within range of best outcome")


func test_ff_primary_high_budget_can_roll_higher_tier() -> void:
	var table := LootTable.new()
	table._primary_loot[LootManager.LootType.Fortunes_Favor] = 1
	table._budget = 28268
	LootManager.DistributeRewards(table, 20)
	var total: int = 0
	for tier in table._drop_result._fortunes_favor.keys():
		total += table._drop_result._fortunes_favor[tier]
	assert_eq(total, 10, "Difficulty 20 should give 10 FF regardless of tier")


func test_supplies_primary_gives_configured_count() -> void:
	var table := LootTable.new()
	table._primary_loot[LootManager.LootType.Supplies] = 2
	table._budget = 0
	LootManager.DistributeRewards(table, 1)
	assert_eq(table._drop_result._supplies, 2, "Primary Supplies count should grant that many supplies")


func test_supplies_secondary_consumes_budget_for_one() -> void:
	var table := LootTable.new()
	table._secondary_loot[LootManager.LootType.Supplies] = 1
	table._budget = LootManager.LOOT_VALUE[LootManager.LootType.Supplies]
	LootManager.DistributeRewards(table, 1)
	assert_eq(table._drop_result._supplies, 1, "Budget with Supplies-only secondary should yield 1 supply")
	assert_lte(table._budget, 0, "Budget should be exhausted after 1 supply")


func test_rarity_rates_sum_to_100() -> void:
	var grouped: Dictionary[Types.Rarity, Array] = {
		Types.Rarity.Common: [1],
		Types.Rarity.Uncommon: [1],
		Types.Rarity.Rare: [1],
	}
	var rates: Dictionary[Types.Rarity, float] = LootManager.GetRarityRates(grouped)
	var total: float = 0.0
	for rarity in rates.keys():
		total += rates[rarity]
	assert_almost_eq(total, 100.0, 0.01, "Rarity rates should sum to 100%")


func test_upgrade_cost_matches_formula() -> void:
	assert_eq(LootManager.GetUpgradeCost(Types.Rarity.Common, 0), GameBalance.BASE_ITEM_UPGRADE_COST * 1 * 1, "Common, level 0")
	assert_eq(LootManager.GetUpgradeCost(Types.Rarity.Common, 3), GameBalance.BASE_ITEM_UPGRADE_COST * 4 * 1, "Common, level 3")
	assert_eq(LootManager.GetUpgradeCost(Types.Rarity.Legendary, 0), GameBalance.BASE_ITEM_UPGRADE_COST * 1 * 5, "Legendary, level 0")
	assert_eq(LootManager.GetUpgradeCost(Types.Rarity.Epic, 5), GameBalance.BASE_ITEM_UPGRADE_COST * 6 * 4, "Epic, level 5")


func test_get_best_rarity_for_item_clamps_at_legendary() -> void:
	assert_eq(LootManager.GetBestRarityForItem(999999999), Types.Rarity.Legendary as int,
		"Even an enormous budget should clamp at Legendary now that Relic is not a rarity")


func test_roll_item_type_is_bounded_and_independent_of_budget() -> void:
	for i in range(50):
		var item_type: Types.Item_Type = LootManager.RollItemType()
		assert_true(item_type == Types.Item_Type.Standard or item_type == Types.Item_Type.Relic,
			"RollItemType should only ever return Standard or Relic")


func test_equipment_drop_costs_the_standard_rarity_price_regardless_of_item_type() -> void:
	# Item type is rolled independently of the rarity budget (Concept_Document.md 3.3.1):
	# whichever preset a drop ends up using, the budget spent must depend on rarity alone.
	# Budget 100 resolves to Common, whose ~143 cost exceeds the starting budget, so the
	# post-primary-loot secondary-loot loop never fires and the delta isolates the
	# Equipment branch's own cost.
	const STARTING_BUDGET: int = 100
	var gear_loot: EquipmentPreset = EquipmentPresetRegistry.Get("Scaled_Greaves")
	var best_rarity_outcome: int = LootManager.GetBestRarityForItem(STARTING_BUDGET)
	var expected_cost: int = int(pow(
			LootManager.LOOT_VALUE[LootManager.LootType.Equipment],
			1.0 + (best_rarity_outcome as float * LootManager.RARITY_VALUE_POWER)))
	var saw_relic: bool = false
	var saw_standard: bool = false
	for i in range(300):
		var table := LootTable.new()
		table._primary_loot[LootManager.LootType.Equipment] = 1
		table._gear_pool = [gear_loot]
		table._budget = STARTING_BUDGET

		LootManager.DistributeRewards(table, 1)

		var equipment: EquipmentPreset = table._drop_result._equipment[0]
		assert_eq(STARTING_BUDGET - table._budget, expected_cost,
			"Budget spent on an Equipment drop should equal the standard-rarity cost regardless of item type")
		assert_eq(equipment._slot, gear_loot._slot,
			"A guaranteed-slot loot table must keep that slot even when the item-type roll swaps in a Relic")
		if(Types.Item_Type.Relic == equipment._item_type):
			saw_relic = true
		else:
			saw_standard = true
	assert_true(saw_standard, "300 rolls at a 5% Relic chance should include Standard drops")
	assert_true(saw_relic, "300 rolls at a 5% Relic chance should include at least one Relic drop")


func test_distribute_rewards_does_not_accumulate_across_calls() -> void:
	var table := LootTable.new()
	table._primary_loot[LootManager.LootType.Silver] = 1
	table._primary_loot[LootManager.LootType.Experience] = 1
	table._budget = LootManager.CalculateBudget(1)

	LootManager.DistributeRewards(table, 1)
	var first_silver: int = table._drop_result._silver
	var first_experience: int = table._drop_result._experience

	table._budget = LootManager.CalculateBudget(1)
	LootManager.DistributeRewards(table, 1)

	assert_eq(table._drop_result._silver, first_silver,
		"Replaying an encounter should not add to the previous silver drop")
	assert_eq(table._drop_result._experience, first_experience,
		"Replaying an encounter should not add to the previous experience drop")


func test_rarity_rates_only_include_present_rarities() -> void:
	var grouped: Dictionary[Types.Rarity, Array] = {
		Types.Rarity.Common: [1],
		Types.Rarity.Rare: [1],
	}
	var rates: Dictionary[Types.Rarity, float] = LootManager.GetRarityRates(grouped)
	assert_false(rates.has(Types.Rarity.Uncommon), "Rarities absent from the pool should not appear in the rates")
	assert_almost_eq(rates[Types.Rarity.Common], 80.0, 0.01, "Common (288) vs Rare (72) should split 80/20")
	assert_almost_eq(rates[Types.Rarity.Rare], 20.0, 0.01, "Rare share should be 20%")


func _PoolTable(p_pool: Array[EquipmentPreset], p_budget: int) -> LootTable:
	var table := LootTable.new()
	table._primary_loot[LootManager.LootType.Equipment] = 1
	table._gear_pool = p_pool
	table._budget = p_budget
	return table

func test_standard_drop_comes_from_the_gear_pool() -> void:
	var pool: Array[EquipmentPreset] = [
		EquipmentPresetRegistry.Get("Briar_Staff"), EquipmentPresetRegistry.Get("Hueless_Slippers")]
	var pool_paths: Array[String] = [pool[0]._preset_path, pool[1]._preset_path]
	var pool_slots: Array[Types.Slot] = [pool[0]._slot, pool[1]._slot]
	for i in range(200):
		var table: LootTable = _PoolTable(pool, 100)
		LootManager.DistributeRewards(table, 1)
		var equipment: EquipmentPreset = table._drop_result._equipment[0]
		if(Types.Item_Type.Relic == equipment._item_type):
			assert_true(pool_slots.has(equipment._slot), "A Relic drop should match a pool preset's slot")
		else:
			assert_true(pool_paths.has(equipment._preset_path), "A Standard drop should come from the pool")

func test_empty_gear_pool_drops_nothing_but_spends_the_budget() -> void:
	var table: LootTable = _PoolTable([], 100)
	LootManager.DistributeRewards(table, 1)
	assert_true(table._drop_result._equipment.is_empty(), "No pool means no gear")
	assert_lt(table._budget, 100, "The drop's cost is still spent")

func test_secondary_equipment_drops_from_the_pool_and_the_loop_ends() -> void:
	var pool: Array[EquipmentPreset] = [EquipmentPresetRegistry.Get("Pew_Shield")]
	var table := LootTable.new()
	table._secondary_loot[LootManager.LootType.Equipment] = 1
	table._gear_pool = pool
	table._budget = LootManager.CalculateBudget(10)
	LootManager.DistributeRewards(table, 10)
	assert_false(table._drop_result._equipment.is_empty(), "A gear-only secondary table should drop gear")
	for equipment in table._drop_result._equipment:
		assert_eq(equipment._slot, Types.Slot.OffHand, "Every secondary drop should come from the pool's slot")
	assert_true(table._budget <= 0, "The secondary loop should spend the budget and end")

func test_equipment_chance_drops_gear_without_spending_the_budget() -> void:
	var table := LootTable.new()
	table._gear_pool = [EquipmentPresetRegistry.Get("Pew_Shield")]
	table._equipment_chance = 1.0
	table._budget = 0
	LootManager.DistributeRewards(table, 5)
	assert_eq(table._drop_result._equipment.size(), 1, "A certain chance should drop exactly one item")
	assert_eq(table._budget, 0, "The chance roll costs no budget")

func test_zero_equipment_chance_drops_no_gear() -> void:
	var table := LootTable.new()
	table._gear_pool = [EquipmentPresetRegistry.Get("Pew_Shield")]
	table._secondary_loot[LootManager.LootType.Experience] = 1
	table._budget = LootManager.CalculateBudget(10)
	LootManager.DistributeRewards(table, 10)
	assert_true(table._drop_result._equipment.is_empty())
