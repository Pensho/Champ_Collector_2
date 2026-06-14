extends GutTest

var _tier: FortuneFavorTier


func before_each() -> void:
	_tier = FortuneFavorTier.new()
	_tier.reward_count = 3
	_tier.silver_weight = 40
	_tier.silver_amount = 20
	_tier.supplies_weight = 30
	_tier.supplies_amount = 10
	_tier.recruitable_champions = _build_preset_pool()


func _build_preset_pool() -> Array[CharacterPreset]:
	var presets: Array[CharacterPreset] = []

	var common_preset := CharacterPreset.new()
	common_preset._name = "Common Champion"
	common_preset._rarity = Types.Rarity.Common
	presets.append(common_preset)

	var uncommon_preset := CharacterPreset.new()
	uncommon_preset._name = "Uncommon Champion"
	uncommon_preset._rarity = Types.Rarity.Uncommon
	presets.append(uncommon_preset)

	return presets


func test_build_rewards_all_true_gate_yields_one_champion_and_remaining_fillers() -> void:
	var gate: Array[bool] = [true, true, true]
	var rewards: Array[Dictionary] = RecruitmentManager.BuildRewards(_tier, gate)

	assert_eq(rewards.size(), 3, "Should produce exactly reward_count rewards")
	assert_eq(rewards[0]["type"], RecruitmentManager.RewardType.CHAMPION, "First slot should be a champion")
	for i in range(1, rewards.size()):
		assert_ne(rewards[i]["type"], RecruitmentManager.RewardType.CHAMPION, "Only the first slot should be a champion")


func test_build_rewards_all_false_gate_yields_zero_champions() -> void:
	var gate: Array[bool] = [false, false, false]
	var rewards: Array[Dictionary] = RecruitmentManager.BuildRewards(_tier, gate)

	assert_eq(rewards.size(), 3, "Should produce exactly reward_count rewards")
	for reward in rewards:
		assert_ne(reward["type"], RecruitmentManager.RewardType.CHAMPION, "No reward should be a champion")


func test_build_rewards_gate_with_single_true_yields_champion_at_that_slot_only() -> void:
	var gate: Array[bool] = [false, true, true]
	var rewards: Array[Dictionary] = RecruitmentManager.BuildRewards(_tier, gate)

	assert_ne(rewards[0]["type"], RecruitmentManager.RewardType.CHAMPION, "First slot should be filler")
	assert_eq(rewards[1]["type"], RecruitmentManager.RewardType.CHAMPION, "Second slot should be the champion")
	assert_ne(rewards[2]["type"], RecruitmentManager.RewardType.CHAMPION, "Third slot should be filler since a champion was already won")


func test_roll_filler_returns_silver_when_supplies_weight_is_zero() -> void:
	for i in 10:
		assert_eq(RecruitmentManager.RollFiller(40, 0), RecruitmentManager.RewardType.SILVER, "With zero supplies weight, filler should always be Silver")


func test_roll_filler_returns_supplies_when_silver_weight_is_zero() -> void:
	for i in 10:
		assert_eq(RecruitmentManager.RollFiller(0, 30), RecruitmentManager.RewardType.SUPPLIES, "With zero silver weight, filler should always be Supplies")


func test_group_by_rarity_buckets_presets_correctly() -> void:
	var grouped: Dictionary[Types.Rarity, Array] = RecruitmentManager.GroupByRarity(_tier.recruitable_champions)

	assert_true(grouped.has(Types.Rarity.Common), "Common rarity bucket should exist")
	assert_true(grouped.has(Types.Rarity.Uncommon), "Uncommon rarity bucket should exist")
	assert_eq(grouped[Types.Rarity.Common].size(), 1, "Common bucket should contain one preset")
	assert_eq(grouped[Types.Rarity.Uncommon].size(), 1, "Uncommon bucket should contain one preset")


func test_pick_champion_by_rarity_only_returns_present_rarities() -> void:
	var grouped: Dictionary[Types.Rarity, Array] = RecruitmentManager.GroupByRarity(_tier.recruitable_champions)

	for i in 10:
		var champion: CharacterPreset = RecruitmentManager.PickChampionByRarity(grouped, LootManager.RARITY_WEIGHTING)
		assert_not_null(champion, "Should never return null on a non-empty pool")
		assert_true(grouped.has(champion._rarity), "Picked champion's rarity should be present in the pool")


func test_build_rewards_brass_tier_has_five_rewards_and_at_most_one_champion() -> void:
	_tier.reward_count = 5
	var gate: Array[bool] = [true, true, true, true, true]
	var rewards: Array[Dictionary] = RecruitmentManager.BuildRewards(_tier, gate)

	assert_eq(rewards.size(), 5, "Brass tier should produce exactly 5 rewards")
	var champion_count: int = 0
	for reward in rewards:
		if(reward["type"] == RecruitmentManager.RewardType.CHAMPION):
			champion_count += 1
	assert_eq(champion_count, 1, "At most one champion should be awarded regardless of reward count")


func test_build_rewards_parchment_tier_has_nine_rewards_and_at_most_one_champion() -> void:
	_tier.reward_count = 9
	var gate: Array[bool] = [true, true, true, true, true, true, true, true, true]
	var rewards: Array[Dictionary] = RecruitmentManager.BuildRewards(_tier, gate)

	assert_eq(rewards.size(), 9, "Parchment tier should produce exactly 9 rewards")
	var champion_count: int = 0
	for reward in rewards:
		if(reward["type"] == RecruitmentManager.RewardType.CHAMPION):
			champion_count += 1
	assert_eq(champion_count, 1, "At most one champion should be awarded regardless of reward count")


func test_brass_tier_resource_loads_with_expected_reward_count_and_tier_type() -> void:
	var tier: FortuneFavorTier = load("res://Data/Recruitment/Brass_Tier.tres")
	assert_eq(tier.reward_count, 5, "Brass tier should have a reward count of 5")
	assert_eq(tier.tier_type, FortuneFavorTier.TierType.BRASS, "Brass tier should have tier_type BRASS")


func test_parchment_tier_resource_loads_with_expected_reward_count_and_tier_type() -> void:
	var tier: FortuneFavorTier = load("res://Data/Recruitment/Parchment_Tier.tres")
	assert_eq(tier.reward_count, 9, "Parchment tier should have a reward count of 9")
	assert_eq(tier.tier_type, FortuneFavorTier.TierType.PARCHMENT, "Parchment tier should have tier_type PARCHMENT")


func test_bone_tier_resource_loads_with_expected_reward_count_and_tier_type() -> void:
	var tier: FortuneFavorTier = load("res://Data/Recruitment/Bone_Tier.tres")
	assert_eq(tier.reward_count, 3, "Bone tier should have a reward count of 3")
	assert_eq(tier.tier_type, FortuneFavorTier.TierType.BONE, "Bone tier should have tier_type BONE")


func test_pick_champion_by_rarity_single_rarity_pool_always_returns_that_champion() -> void:
	var single_preset := CharacterPreset.new()
	single_preset._name = "Only Champion"
	single_preset._rarity = Types.Rarity.Rare
	var presets: Array[CharacterPreset] = [single_preset]
	var grouped: Dictionary[Types.Rarity, Array] = RecruitmentManager.GroupByRarity(presets)

	for i in 10:
		var champion: CharacterPreset = RecruitmentManager.PickChampionByRarity(grouped, LootManager.RARITY_WEIGHTING)
		assert_eq(champion, single_preset, "Single-rarity pool should always return the only champion")
