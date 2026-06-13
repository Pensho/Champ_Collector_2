extends GutTest


func _ff_primary_table() -> LootTable:
	var table := LootTable.new()
	table._primary_loot[LootManager.LootType.Fortunes_Favor] = 1
	table._budget = 0
	return table


func test_ff_primary_diff_1_gives_1() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 1)
	assert_eq(table._drop_result._fortunes_favor, 1, "Difficulty 1 should give 1 FF (minimum)")


func test_ff_primary_diff_2_gives_1() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 2)
	assert_eq(table._drop_result._fortunes_favor, 1, "Difficulty 2 should still give 1 FF")


func test_ff_primary_diff_4_gives_2() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 4)
	assert_eq(table._drop_result._fortunes_favor, 2, "Difficulty 4 should give 2 FF")


func test_ff_primary_diff_10_gives_5() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 10)
	assert_eq(table._drop_result._fortunes_favor, 5, "Difficulty 10 should give 5 FF")


func test_ff_primary_diff_20_gives_10() -> void:
	var table := _ff_primary_table()
	LootManager.DistributeRewards(table, 20)
	assert_eq(table._drop_result._fortunes_favor, 10, "Difficulty 20 should give 10 FF")


func test_ff_secondary_consumes_budget_for_one() -> void:
	var table := LootTable.new()
	table._secondary_loot[LootManager.LootType.Fortunes_Favor] = 1
	table._budget = 500
	LootManager.DistributeRewards(table, 1)
	assert_eq(table._drop_result._fortunes_favor, 1, "500 budget with FF-only secondary should yield 1 FF")
	assert_lte(table._budget, 0, "Budget should be exhausted after 1 FF")


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
