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
	Types.Rarity.Common: 288, 		# 143 budget cost
	Types.Rarity.Uncommon: 144,		# budget 413 required
	Types.Rarity.Rare: 72,			# budget 1188 required
	Types.Rarity.Epic: 36,			# budget 3418 required
	Types.Rarity.Legendary: 18,		# budget 9830 required
	Types.Rarity.Relic: 7,			# budget 28,268 required
}
const SPAN_RANGE: int = 3
const LOOT_VALUE: Dictionary[LootType, int] = {
	LootType.Experience : 10,
	LootType.Silver : 10,
	LootType.Equipment : 50,
	LootType.Fortunes_Favor : 500,
	LootType.Supplies : 300,
}
const RARITY_VALUE_POWER: float = 0.27

static func CalculateBudget(p_difficulty: int) -> int:
	# Given the difficulty options of 1-20
	# This yields a budget range of 159 - 50456
	return int(pow(2 + (10 * p_difficulty), 2.04))

static func GetBestRarityForItem(p_budget: int) -> int:
	var rarity_power_value = log(float(p_budget))/log(LOOT_VALUE[LootType.Equipment])
	var best_outcome = int((rarity_power_value - 1.0) / RARITY_VALUE_POWER)
	
	if(Types.Rarity.Common >= best_outcome):
		return Types.Rarity.Common as int
	elif(Types.Rarity.Relic < best_outcome):
		best_outcome = Types.Rarity.Relic as int
	
	return best_outcome

static func RollRarityForItem(p_best_outcome: int) -> Types.Rarity:
	print("rarity for Equipment available: ", p_best_outcome)
	
	var cumulative_weights: Dictionary[Types.Rarity, int]
	var current_sum: int = 0
	var worst_outcome: int = max(p_best_outcome - SPAN_RANGE, 1)
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

static func DistributeRewards(p_loot_table: LootTable, p_difficulty: int) -> void:
	print("Loot budget from battle is: ", p_loot_table._budget)
	for type in p_loot_table._primary_loot.keys():
		match type:
			LootType.Experience:
				for i in range(p_loot_table._primary_loot[type]):
					p_loot_table._drop_result._experience += p_difficulty
					p_loot_table._budget -= LOOT_VALUE[LootType.Experience]
					print("Received Experience, budget left: ", p_loot_table._budget)
			LootType.Silver:
				p_loot_table._drop_result._silver += p_difficulty
				p_loot_table._budget -= LOOT_VALUE[LootType.Silver]
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
				pass
			LootType.Supplies:
				pass
			_:
				print("Invalid reward type specified while trying to distribute rewards!")
	print("budget before secondary rewards: ", p_loot_table._budget)
	while p_loot_table._budget > 0:
		match GetWeigthedRandom(p_loot_table._secondary_loot):
			LootType.Experience:
				p_loot_table._drop_result._experience += p_difficulty
				p_loot_table._budget -= LOOT_VALUE[LootType.Experience]
				print("Received secondary Experience, budget left: ", p_loot_table._budget)
			LootType.Silver:
				p_loot_table._drop_result._silver += p_difficulty
				p_loot_table._budget -= LOOT_VALUE[LootType.Silver]
				print("Received secondary Silver, budget left: ", p_loot_table._budget)
			LootType.Equipment:
				pass
				#p_loot_table._budget -= LOOT_VALUE[LootType.Equipment]
			LootType.Fortunes_Favor:
				pass
				#p_loot_table._budget -= LOOT_VALUE[LootType.Fortunes_Favor]
			LootType.Supplies:
				pass
				#p_loot_table._budget -= LOOT_VALUE[LootType.Supplies]
			_:
				print("Invalid reward type specified while trying to distribute rewards!")

static func GetWeigthedRandom(p_secondary_loot: Dictionary[LootManager.LootType, int]):
	var total_weight = 0
	for type in p_secondary_loot.keys():
		total_weight += p_secondary_loot[type]
	
	var roll = randi_range(0, total_weight)
	var current_weight = 0
	for type in p_secondary_loot.keys():
		current_weight += p_secondary_loot[type]
		if(roll <= current_weight):
			return type
