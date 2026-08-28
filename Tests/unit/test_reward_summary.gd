extends GutTest

var summary: RewardSummaryUI


func before_each() -> void:
	summary = RewardSummaryUI.new()
	summary._label_experience = Label.new()
	summary._label_silver = Label.new()
	summary._label_supplies = Label.new()
	summary._h_box_container_items = HBoxContainer.new()
	summary.add_child(summary._label_experience)
	summary.add_child(summary._label_silver)
	summary.add_child(summary._label_supplies)
	summary.add_child(summary._h_box_container_items)
	add_child_autoqfree(summary)


func _EmptyDropResult() -> LootTable.DropResult:
	return LootTable.DropResult.new()


func test_zero_valued_rewards_hide_their_labels() -> void:
	summary.SetRewards(_EmptyDropResult())
	assert_false(summary._label_experience.visible)
	assert_false(summary._label_silver.visible)
	assert_false(summary._label_supplies.visible)


func test_non_zero_rewards_show_their_labels_with_written_out_text() -> void:
	var drop_result: LootTable.DropResult = _EmptyDropResult()
	drop_result._experience = 24
	drop_result._silver = 10
	drop_result._supplies = 2
	summary.SetRewards(drop_result)

	assert_true(summary._label_experience.visible)
	assert_eq(summary._label_experience.text, "Experience: 24")
	assert_true(summary._label_silver.visible)
	assert_eq(summary._label_silver.text, "Silver: 10")
	assert_true(summary._label_supplies.visible)
	assert_eq(summary._label_supplies.text, "Supplies: 2")


func test_all_empty_drop_result_hides_the_widget() -> void:
	summary.SetRewards(_EmptyDropResult())
	assert_false(summary.visible)


func test_any_reward_shows_the_widget() -> void:
	var drop_result: LootTable.DropResult = _EmptyDropResult()
	drop_result._silver = 5
	summary.SetRewards(drop_result)
	assert_true(summary.visible)


func test_gear_drop_adds_one_icon_slot() -> void:
	var drop_result: LootTable.DropResult = _EmptyDropResult()
	drop_result._equipment = EquipmentPresetRegistry.Get("Red_Boots").duplicate(true)
	summary.SetRewards(drop_result)
	assert_eq(summary._h_box_container_items.get_child_count(), 1)


func test_duplicate_reagent_keys_collapse_into_one_slot_with_a_count() -> void:
	var drop_result: LootTable.DropResult = _EmptyDropResult()
	drop_result._reagents = ["Lesser_Tincture", "Lesser_Tincture"]
	summary.SetRewards(drop_result)

	assert_eq(summary._h_box_container_items.get_child_count(), 1)
	var slot: RewardItemSlotUI = summary._h_box_container_items.get_child(0)
	assert_eq(slot._label_count.text, "2")


func test_distinct_rewards_each_get_their_own_icon_slot() -> void:
	var drop_result: LootTable.DropResult = _EmptyDropResult()
	drop_result._equipment = EquipmentPresetRegistry.Get("Red_Boots").duplicate(true)
	drop_result._reagents = ["Lesser_Tincture"]
	drop_result._fortunes_favor[FortuneFavorTier.TierType.BONE] = 1
	summary.SetRewards(drop_result)

	assert_eq(summary._h_box_container_items.get_child_count(), 3)


func test_fortunes_favor_with_zero_count_does_not_add_a_slot() -> void:
	var drop_result: LootTable.DropResult = _EmptyDropResult()
	drop_result._fortunes_favor[FortuneFavorTier.TierType.BONE] = 0
	summary.SetRewards(drop_result)
	assert_eq(summary._h_box_container_items.get_child_count(), 0)
	assert_false(summary.visible)
