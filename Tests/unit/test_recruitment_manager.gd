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


func test_pity_bonus_is_zero_below_threshold() -> void:
	assert_eq(RecruitmentManager.PityBonus(0), 0.0, "Zero duplicates should have no bonus")
	assert_eq(RecruitmentManager.PityBonus(5), 0.0, "Five duplicates should have no bonus")


func test_pity_bonus_starts_at_threshold() -> void:
	assert_eq(RecruitmentManager.PityBonus(6), 0.10, "Sixth duplicate should grant the first +10% bonus")


func test_pity_bonus_accumulates_past_threshold() -> void:
	assert_almost_eq(RecruitmentManager.PityBonus(7), 0.20, 0.0001, "Seventh duplicate should grant +20%")
	assert_almost_eq(RecruitmentManager.PityBonus(8), 0.30, 0.0001, "Eighth duplicate should grant +30%")


func test_pity_bonus_caps_at_one_hundred_percent() -> void:
	assert_eq(RecruitmentManager.PityBonus(15), 1.0, "Bonus should reach a guaranteed 100% by the 15th duplicate")
	assert_eq(RecruitmentManager.PityBonus(30), 1.0, "Bonus should stay capped past the guarantee point")


func test_unowned_presets_filters_by_owned_names() -> void:
	var owned: Dictionary = {"Common Champion": true}
	var unowned: Array[CharacterPreset] = RecruitmentManager.UnownedPresets(_tier.recruitable_champions, owned)

	assert_eq(unowned.size(), 1, "Only the unowned preset should remain")
	assert_eq(unowned[0]._name, "Uncommon Champion", "Uncommon Champion should be the unowned preset")


func test_unowned_presets_with_no_owned_names_returns_full_pool() -> void:
	var unowned: Array[CharacterPreset] = RecruitmentManager.UnownedPresets(_tier.recruitable_champions, {})
	assert_eq(unowned.size(), _tier.recruitable_champions.size(), "Empty owned set should leave the whole pool unowned")


func test_unowned_presets_with_everything_owned_returns_empty() -> void:
	var owned: Dictionary = {"Common Champion": true, "Uncommon Champion": true}
	var unowned: Array[CharacterPreset] = RecruitmentManager.UnownedPresets(_tier.recruitable_champions, owned)
	assert_true(unowned.is_empty(), "Fully-owned pool should yield no unowned presets")


func test_pick_champion_with_pity_at_full_bonus_only_returns_unowned() -> void:
	var owned: Dictionary = {"Common Champion": true}
	for i in 10:
		var champion: CharacterPreset = RecruitmentManager.PickChampionWithPity(
				_tier.recruitable_champions, LootManager.RARITY_WEIGHTING, owned, 1.0)
		assert_eq(champion._name, "Uncommon Champion", "Full pity bonus should always pick the unowned champion")


func test_pick_champion_with_pity_at_zero_bonus_can_return_owned() -> void:
	var single_preset := CharacterPreset.new()
	single_preset._name = "Only Champion"
	single_preset._rarity = Types.Rarity.Rare
	var presets: Array[CharacterPreset] = [single_preset]
	var owned: Dictionary = {"Only Champion": true}

	var champion: CharacterPreset = RecruitmentManager.PickChampionWithPity(
			presets, LootManager.RARITY_WEIGHTING, owned, 0.0)
	assert_eq(champion, single_preset, "Zero pity bonus should pick normally even if it is owned")


func test_pick_champion_with_pity_and_fully_owned_pool_still_returns_a_champion() -> void:
	var owned: Dictionary = {"Common Champion": true, "Uncommon Champion": true}
	var champion: CharacterPreset = RecruitmentManager.PickChampionWithPity(
			_tier.recruitable_champions, LootManager.RARITY_WEIGHTING, owned, 1.0)
	assert_not_null(champion, "A fully-owned pool should still yield a valid champion")
