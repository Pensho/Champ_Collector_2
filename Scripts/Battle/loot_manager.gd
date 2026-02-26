class_name LootManager extends Node

const Types = preload("uid://bkpa0hv70oydy")

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
	Types.Rarity.Common: 288,
	Types.Rarity.Uncommon: 144,
	Types.Rarity.Rare: 72,
	Types.Rarity.Epic: 36,
	Types.Rarity.Legendary: 18,
	Types.Rarity.Relic: 7,
}
const SPAN_RANGE: int = 3
const LOOT_VALUE: Dictionary[LootType, int] = {
	LootType.Experience : 10,
	LootType.Silver : 10,
	LootType.Equipment : 50,
	LootType.Fortunes_Favor : 500,
	LootType.Supplies : 300,
}
const RARITY_VALUE_POWER: float = 0.3

static func CalculateBudget(p_base_val: int, p_difficulty: int, p_supply_cost: int, p_loot_table: LootTable) -> void:
	p_loot_table._budget = int(p_base_val * pow(p_difficulty, 1.2)) + (p_base_val * p_supply_cost)

static func RollRarityForItem(p_budget: int) -> Types.Rarity:
	var rarity_power_value = log(float(p_budget))/log(LOOT_VALUE[LootType.Equipment])
	var best_outcome: int = int((rarity_power_value - 1.0) / RARITY_VALUE_POWER)
	
	# Will always give Common as the smallest possible outcome
	if(Types.Rarity.Common >= best_outcome):
		return Types.Rarity.Common
	# Will always give Relic as the largest possible outcome
	elif(Types.Rarity.Relic < best_outcome):
		best_outcome = Types.Rarity.Relic as int
	
	var cumulative_weights: Dictionary[Types.Rarity, int]
	var current_sum: int = 0
	var span_bottom: int = max(best_outcome - SPAN_RANGE, 1)
	for i in range(span_bottom, best_outcome + 1):
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

func DistributeRewards() -> void:
	pass
