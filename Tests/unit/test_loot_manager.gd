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
