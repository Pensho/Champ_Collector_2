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

const LOOT_VALUE: Dictionary[LootType, int] = {
	LootType.Experience : 10,
	LootType.Silver : 10,
	LootType.Equipment : 50,
	LootType.Fortunes_Favor : 500,
	LootType.Supplies : 300,
}
const RARITY_VALUE_POWER: float = 0.3

func CalculateBudget(p_base_val: int, p_difficulty: int, p_supply_cost: int, p_loot_table: LootTable) -> void:
	p_loot_table._budget = int(p_base_val * pow(p_difficulty, 1.2)) + (p_base_val * p_supply_cost)

func RollRarityForItem(p_budget: int) -> Types.Rarity:
	var rarity_power_value = log(float(p_budget))/log(LOOT_VALUE[LootType.Equipment])
	var best_outcome: int = int((rarity_power_value - 1.0) / RARITY_VALUE_POWER)
	
	# Will always give Common as the smallest possible outcome
	if(Types.Rarity.Common >= best_outcome):
		return Types.Rarity.Common
	# Will always give Relic as the largest possible outcome
	elif(Types.Rarity.Relic < best_outcome):
		best_outcome = Types.Rarity.Relic as int
	
	var result: int = best_outcome # replace this with a weighted roll allowing rarity to become 2 levels lower at most.
	
	return result as Types.Rarity

func DistributeRewards() -> void:
	pass
