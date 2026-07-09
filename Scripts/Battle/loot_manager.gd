class_name LootManager extends Node

enum LootType
{
	Experience,
	Silver,
	Equipment,
	Fortunes_Favor,
	Supplies,
}

# First Sub-series: {7, 18, 36, 72}
# 7: 5.26% - 18: 13.53% - 36: 27.07% - 72: 54.14%
# Second Sub-series: {18, 36, 72, 144}
# 18: 6.67% - 36: 13.33% - 72: 26.67% - 144: 53.33%
# Note that the Third series is exactly the same as the second.
const RARITY_WEIGHTING: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Common: 288, 		# 143 budget cost
	Types.Rarity.Uncommon: 144,		# budget 413 required
	Types.Rarity.Rare: 72,			# budget 1188 required
	Types.Rarity.Epic: 36,			# budget 3418 required
	Types.Rarity.Legendary: 18,		# budget 9830 required
	Types.Rarity.Relic: 7,			# budget 28,268 required
}
const GEAR_RARITY_RANGE: int = 3
const FORTUNE_FAVOR_TIER_RANGE: int = 2 # only 3 tiers exist, so range can cover all
const FORTUNE_FAVOR_TIER_WEIGHTING: Dictionary[FortuneFavorTier.TierType, int] = {
	FortuneFavorTier.TierType.BONE: 4,
	FortuneFavorTier.TierType.BRASS: 2,
	FortuneFavorTier.TierType.PARCHMENT: 1,
}
const LOOT_VALUE: Dictionary[LootType, int] = {
	LootType.Experience : 18,
	LootType.Silver : 10,
	LootType.Equipment : 50,
	LootType.Fortunes_Favor : 500,
	LootType.Supplies : 300,
}
const RARITY_VALUE_POWER: float = 0.27
const RARITY_SELLING_POWER: float = 0.15

static func CalculateBudget(p_difficulty: int) -> int:
	# Given the difficulty options of 1-20
	# This yields a budget range of 159 - 50456
	return int(pow(2 + (10 * p_difficulty), 2.04))

static func GetBestRarityForItem(p_budget: int) -> int:
	var rarity_power_value = log(float(p_budget))/log(LOOT_VALUE[LootType.Equipment])
	var best_outcome = int((rarity_power_value - 1.0) / RARITY_VALUE_POWER)
	
	if(Types.Rarity.Common >= best_outcome):
		return Types.Rarity.Common as int
	if(Types.Rarity.Relic < best_outcome):
		best_outcome = Types.Rarity.Relic as int
	
	return best_outcome

static func RollRarityForItem(p_best_outcome: int) -> Types.Rarity:
	print("rarity for Equipment available: ", p_best_outcome)
	
	var cumulative_weights: Dictionary[Types.Rarity, int]
	var current_sum: int = 0
	var worst_outcome: int = max(p_best_outcome - GEAR_RARITY_RANGE, 1)
	for i in range(worst_outcome, p_best_outcome + 1):
		current_sum += RARITY_WEIGHTING[i as Types.Rarity]
		cumulative_weights[i as Types.Rarity] = current_sum
	var total_weight = current_sum
	
	var random_roll = randi_range(0, total_weight)
	
	var result: Types.Rarity = Types.Rarity.Common
	for rarity in cumulative_weights.keys():
		if(random_roll <= cumulative_weights[rarity]):
			result = rarity
			break
	
	return result

static func GetBestFortuneFavorTier(p_budget: int) -> int:
	var tier_power_value = log(float(p_budget))/log(LOOT_VALUE[LootType.Fortunes_Favor])
	var best_outcome = int((tier_power_value - 1.0) / RARITY_VALUE_POWER)

	if(FortuneFavorTier.TierType.BONE >= best_outcome):
		return FortuneFavorTier.TierType.BONE as int
	if(FortuneFavorTier.TierType.PARCHMENT < best_outcome):
		best_outcome = FortuneFavorTier.TierType.PARCHMENT as int

	return best_outcome

static func RollFortuneFavorTier(p_best_outcome: int) -> FortuneFavorTier.TierType:
	var cumulative_weights: Dictionary[FortuneFavorTier.TierType, int]
	var current_sum: int = 0
	var worst_outcome: int = max(p_best_outcome - FORTUNE_FAVOR_TIER_RANGE, 0)
	for i in range(worst_outcome, p_best_outcome + 1):
		current_sum += FORTUNE_FAVOR_TIER_WEIGHTING[i as FortuneFavorTier.TierType]
		cumulative_weights[i as FortuneFavorTier.TierType] = current_sum
	var total_weight = current_sum

	var random_roll = randi_range(0, total_weight)

	var result: FortuneFavorTier.TierType = FortuneFavorTier.TierType.BONE
	for tier in cumulative_weights.keys():
		if(random_roll <= cumulative_weights[tier]):
			result = tier
			break

	return result

static func DistributeRewards(p_loot_table: LootTable, p_difficulty: int) -> void:
	print("Loot budget from battle is: ", p_loot_table._budget)
	for type in p_loot_table._primary_loot.keys():
		match type:
			LootType.Experience:
				for i in range(p_loot_table._primary_loot[type]):
					p_loot_table._drop_result._experience += p_difficulty
					p_loot_table._budget -= p_difficulty + (float(LOOT_VALUE[LootType.Experience]) * (float(p_difficulty))) as int
					print("Received Experience, budget left: ", p_loot_table._budget)
			LootType.Silver:
				p_loot_table._drop_result._silver += p_difficulty
				p_loot_table._budget -= (float(LOOT_VALUE[LootType.Silver]) * (float(p_difficulty) * 0.85)) as int
				print("Received Silver, budget left: ", p_loot_table._budget)
			LootType.Equipment:
				for i in range(p_loot_table._primary_loot[type]):
					var best_rarity_outcome = GetBestRarityForItem(p_loot_table._budget)
					var rarity: Types.Rarity = RollRarityForItem(best_rarity_outcome)
					var cost: int = int(pow(LOOT_VALUE[LootType.Equipment], 1.0 + (best_rarity_outcome as float * RARITY_VALUE_POWER)))
					p_loot_table._drop_result._equipment = p_loot_table._gear_loot.duplicate(true)
					p_loot_table._drop_result._equipment._rarity = rarity
					p_loot_table._drop_result._equipment.Setup()
					p_loot_table._budget -= cost
					print("Received Equipment, budget left: ", p_loot_table._budget)
			LootType.Fortunes_Favor:
				var ff_count: int = max(1, int(p_difficulty / 2.0))
				var best_tier_outcome: int = GetBestFortuneFavorTier(p_loot_table._budget)
				var tier: FortuneFavorTier.TierType = RollFortuneFavorTier(best_tier_outcome)
				var cost: int = int(pow(
						LOOT_VALUE[LootType.Fortunes_Favor], 1.0 + (best_tier_outcome as float * RARITY_VALUE_POWER)))
				p_loot_table._drop_result._fortunes_favor[tier] = p_loot_table._drop_result._fortunes_favor.get(tier, 0) + ff_count
				p_loot_table._budget -= cost * ff_count
				print("Received Fortunes Favor x", ff_count, " (tier ", tier, "), budget left: ", p_loot_table._budget)
			LootType.Supplies:
				for i in range(p_loot_table._primary_loot[type]):
					p_loot_table._drop_result._supplies += 1
					p_loot_table._budget -= LOOT_VALUE[LootType.Supplies]
					print("Received Supplies, budget left: ", p_loot_table._budget)
			_:
				print("Invalid reward type specified while trying to distribute rewards!")
	print("budget before secondary rewards: ", p_loot_table._budget)
	while p_loot_table._budget > 0:
		match GetWeigthedRandom(p_loot_table._secondary_loot):
			LootType.Experience:
				p_loot_table._drop_result._experience += p_difficulty
				p_loot_table._budget -= p_difficulty + (float(LOOT_VALUE[LootType.Experience]) * (float(p_difficulty))) as int
				print("Received secondary Experience, budget left: ", p_loot_table._budget)
			LootType.Silver:
				p_loot_table._drop_result._silver += p_difficulty
				p_loot_table._budget -= (float(LOOT_VALUE[LootType.Silver]) * (float(p_difficulty) * 0.85)) as int
				print("Received secondary Silver, budget left: ", p_loot_table._budget)
			LootType.Equipment:
				pass
				#p_loot_table._budget -= LOOT_VALUE[LootType.Equipment]
			LootType.Fortunes_Favor:
				var best_tier_outcome: int = GetBestFortuneFavorTier(p_loot_table._budget)
				var tier: FortuneFavorTier.TierType = RollFortuneFavorTier(best_tier_outcome)
				p_loot_table._drop_result._fortunes_favor[tier] = p_loot_table._drop_result._fortunes_favor.get(tier, 0) + 1
				p_loot_table._budget -= LOOT_VALUE[LootType.Fortunes_Favor]
				print("Received secondary Fortunes Favor (tier ", tier, "), budget left: ", p_loot_table._budget)
			LootType.Supplies:
				p_loot_table._drop_result._supplies += 1
				p_loot_table._budget -= LOOT_VALUE[LootType.Supplies]
				print("Received secondary Supplies, budget left: ", p_loot_table._budget)
			_:
				print("Invalid reward type specified while trying to distribute rewards!")

static func GetWeigthedRandom(p_secondary_loot: Dictionary[LootManager.LootType, int]) -> LootManager.LootType:
	var chosen_type: LootManager.LootType
	var total_weight = 0
	for type in p_secondary_loot.keys():
		total_weight += p_secondary_loot[type]
	
	var roll = randi_range(0, total_weight)
	var current_weight = 0
	for type in p_secondary_loot.keys():
		current_weight += p_secondary_loot[type]
		if(roll <= current_weight):
			chosen_type = type
			break
	return chosen_type

static func GetSellValue(p_rarity: Types.Rarity) -> int:
	return int(pow(LOOT_VALUE[LootType.Equipment], 1.0 + (float(p_rarity) * RARITY_SELLING_POWER)))

static func GetUpgradeCost(p_rarity: Types.Rarity, p_current_level: int) -> int:
	return GameBalance.BASE_ITEM_UPGRADE_COST * (p_current_level + 1) * int(p_rarity)

static func GetRarityRates(p_grouped: Dictionary[Types.Rarity, Array]) -> Dictionary[Types.Rarity, float]:
	var total_weight: int = 0
	for rarity in RARITY_WEIGHTING.keys():
		if(p_grouped.has(rarity)):
			total_weight += RARITY_WEIGHTING[rarity]

	var rates: Dictionary[Types.Rarity, float] = {}
	for rarity in RARITY_WEIGHTING.keys():
		if(p_grouped.has(rarity)):
			rates[rarity] = (float(RARITY_WEIGHTING[rarity]) / float(total_weight)) * 100.0
	return rates
