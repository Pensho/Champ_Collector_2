extends GutTest

func _table() -> LootTable:
	var table := LootTable.new()
	table._primary_loot[LootManager.LootType.Experience] = 3
	table._primary_loot[LootManager.LootType.Equipment] = 1
	table._secondary_loot[LootManager.LootType.Silver] = 5
	table._secondary_loot[LootManager.LootType.Reagent] = 3
	table._reagent_max_rarity = Types.Rarity.Rare
	return table

func test_entries_covers_primary_and_secondary_types() -> void:
	var entries: Array[Dictionary] = DropPreview.Entries(_table(), 5)
	var types: Array = []
	for entry in entries:
		types.append(entry["type"])
	assert_has(types, LootManager.LootType.Experience)
	assert_has(types, LootManager.LootType.Equipment)
	assert_has(types, LootManager.LootType.Silver)
	assert_has(types, LootManager.LootType.Reagent)

func test_primary_entries_are_flagged_guaranteed() -> void:
	var entries: Array[Dictionary] = DropPreview.Entries(_table(), 5)
	for entry in entries:
		match entry["type"]:
			LootManager.LootType.Experience, LootManager.LootType.Equipment:
				assert_true(entry["guaranteed"], "Primary loot entries should be marked guaranteed")
			LootManager.LootType.Silver, LootManager.LootType.Reagent:
				assert_false(entry["guaranteed"], "Secondary loot entries should not be marked guaranteed")

func test_a_type_present_in_both_primary_and_secondary_is_not_duplicated() -> void:
	var table := _table()
	table._secondary_loot[LootManager.LootType.Equipment] = 1
	var entries: Array[Dictionary] = DropPreview.Entries(table, 5)
	var count: int = 0
	for entry in entries:
		if(LootManager.LootType.Equipment == entry["type"]):
			count += 1
	assert_eq(count, 1, "A type listed in both primary and secondary loot should appear once")

func test_rarity_band_rises_with_difficulty() -> void:
	var table := _table()
	var low_entries: Array[Dictionary] = DropPreview.Entries(table, 1)
	var high_entries: Array[Dictionary] = DropPreview.Entries(table, 20)
	var low_rarity: int = _rarity_for_type(low_entries, LootManager.LootType.Equipment)
	var high_rarity: int = _rarity_for_type(high_entries, LootManager.LootType.Equipment)
	assert_true(high_rarity >= low_rarity, "A higher difficulty should never yield a lower achievable rarity band")

func test_reagent_band_respects_reagent_max_rarity() -> void:
	var table := _table()
	table._reagent_max_rarity = Types.Rarity.Uncommon
	var entries: Array[Dictionary] = DropPreview.Entries(table, 20)
	var rarity: int = _rarity_for_type(entries, LootManager.LootType.Reagent)
	assert_eq(rarity, Types.Rarity.Uncommon as int, "The reagent band must be capped by the loot table's max rarity")

func test_null_loot_table_returns_empty_array() -> void:
	var entries: Array[Dictionary] = DropPreview.Entries(null, 5)
	assert_eq(entries.size(), 0, "A null loot table should produce no drop entries")

func test_entries_does_not_mutate_the_loot_table() -> void:
	var table := _table()
	var budget_before: int = table._budget
	var drop_result_before = table._drop_result
	DropPreview.Entries(table, 5)
	assert_eq(table._budget, budget_before, "Reading drop entries must not spend the loot table's budget")
	assert_same(table._drop_result, drop_result_before, "Reading drop entries must not roll a drop result")

func _rarity_for_type(p_entries: Array[Dictionary], p_type: LootManager.LootType) -> int:
	for entry in p_entries:
		if(entry["type"] == p_type):
			return entry["rarity"]
	return -1

func test_should_show_reagent_step_false_when_none_owned() -> void:
	assert_false(PreBattleMenu.ShouldShowReagentStep({}), "An empty inventory should skip the reagent step")

func test_should_show_reagent_step_true_when_any_owned() -> void:
	assert_true(
			PreBattleMenu.ShouldShowReagentStep({"Mending_Icon_Common": 2}),
			"Owning any reagent should require the reagent step")
